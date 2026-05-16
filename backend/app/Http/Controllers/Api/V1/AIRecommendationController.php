<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AIRecommendation;
use App\Models\AIRecommendationFeedback;
use App\Models\AIUserDailyScore;
use App\Services\AI\RecommendationRuleService;
use App\Services\AI\RecommendationScoringService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AIRecommendationController extends Controller
{
    public function __construct(
        protected RecommendationRuleService $recommendationRuleService,
        protected RecommendationScoringService $recommendationScoringService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'module' => ['nullable', 'string'],
            'status' => ['nullable', 'string'],
            'severity' => ['nullable', 'string'],
            'type' => ['nullable', 'string'],
            'active_only' => ['nullable', 'boolean'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $user = $request->user();

        $query = AIRecommendation::query()
            ->where('user_id', $user->id)
            ->with(['rule:id,rule_code,rule_name,module,severity,priority']);

        if (!empty($validated['module'])) {
            $query->where('module', $validated['module']);
        }

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        if (!empty($validated['severity'])) {
            $query->where('severity', $validated['severity']);
        }

        if (!empty($validated['type'])) {
            $query->where('recommendation_type', $validated['type']);
        }

        if (($validated['active_only'] ?? false) === true) {
            $query->active()->notExpired();
        }

        $limit = $validated['limit'] ?? 20;

        $recommendations = $query
            ->orderBy('priority')
            ->orderByDesc('generated_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'AI recommendations retrieved successfully.',
            'data' => [
                'recommendations' => $recommendations,
                'summary' => [
                    'total' => $recommendations->count(),
                    'pending' => $recommendations->where('status', AIRecommendation::STATUS_PENDING)->count(),
                    'viewed' => $recommendations->where('status', AIRecommendation::STATUS_VIEWED)->count(),
                    'accepted' => $recommendations->where('status', AIRecommendation::STATUS_ACCEPTED)->count(),
                    'dismissed' => $recommendations->where('status', AIRecommendation::STATUS_DISMISSED)->count(),
                    'completed' => $recommendations->where('status', AIRecommendation::STATUS_COMPLETED)->count(),
                    'expired' => $recommendations->where('status', AIRecommendation::STATUS_EXPIRED)->count(),
                ],
            ],
        ]);
    }

    public function generate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => ['nullable', 'date'],
            'store_daily_score' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        $date = !empty($validated['date'])
            ? now()->parse($validated['date'])
            : now();

        $result = DB::transaction(function () use ($user, $date, $validated) {
            if (($validated['store_daily_score'] ?? true) === true) {
                $this->recommendationScoringService->calculateAndStoreForUser($user, $date);
            }

            return $this->recommendationRuleService->generateForUser($user, $date);
        });

        return response()->json([
            'success' => true,
            'message' => 'AI recommendations generated successfully.',
            'data' => $result,
        ]);
    }

    public function markViewed(Request $request, AIRecommendation $recommendation): JsonResponse
    {
        $this->authorizeRecommendationOwner($request, $recommendation);

        $recommendation->markViewed();

        return response()->json([
            'success' => true,
            'message' => 'Recommendation marked as viewed.',
            'data' => [
                'recommendation' => $recommendation->fresh(),
            ],
        ]);
    }

    public function accept(Request $request, AIRecommendation $recommendation): JsonResponse
    {
        $this->authorizeRecommendationOwner($request, $recommendation);

        DB::transaction(function () use ($request, $recommendation) {
            $recommendation->accept();

            AIRecommendationFeedback::create([
                'recommendation_id' => $recommendation->id,
                'user_id' => $request->user()->id,
                'feedback_type' => AIRecommendationFeedback::TYPE_ACCEPTED,
                'feedback_value' => null,
                'feedback_comment' => null,
                'metadata' => [
                    'source' => 'api_accept_endpoint',
                ],
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Recommendation accepted successfully.',
            'data' => [
                'recommendation' => $recommendation->fresh(),
            ],
        ]);
    }

    public function dismiss(Request $request, AIRecommendation $recommendation): JsonResponse
    {
        $this->authorizeRecommendationOwner($request, $recommendation);

        $validated = $request->validate([
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);

        DB::transaction(function () use ($request, $recommendation, $validated) {
            $recommendation->dismiss();

            AIRecommendationFeedback::create([
                'recommendation_id' => $recommendation->id,
                'user_id' => $request->user()->id,
                'feedback_type' => AIRecommendationFeedback::TYPE_DISMISSED,
                'feedback_value' => null,
                'feedback_comment' => $validated['reason'] ?? null,
                'metadata' => [
                    'source' => 'api_dismiss_endpoint',
                ],
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Recommendation dismissed successfully.',
            'data' => [
                'recommendation' => $recommendation->fresh(),
            ],
        ]);
    }

    public function complete(Request $request, AIRecommendation $recommendation): JsonResponse
    {
        $this->authorizeRecommendationOwner($request, $recommendation);

        DB::transaction(function () use ($request, $recommendation) {
            $recommendation->complete();

            AIRecommendationFeedback::create([
                'recommendation_id' => $recommendation->id,
                'user_id' => $request->user()->id,
                'feedback_type' => AIRecommendationFeedback::TYPE_COMPLETED,
                'feedback_value' => null,
                'feedback_comment' => null,
                'metadata' => [
                    'source' => 'api_complete_endpoint',
                ],
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Recommendation completed successfully.',
            'data' => [
                'recommendation' => $recommendation->fresh(),
            ],
        ]);
    }

    public function feedback(Request $request, AIRecommendation $recommendation): JsonResponse
    {
        $this->authorizeRecommendationOwner($request, $recommendation);

        /*
        |--------------------------------------------------------------------------
        | Backward Compatible Feedback Payload
        |--------------------------------------------------------------------------
        | Step 72 QA exposed two payload formats in use:
        | 1. Current frontend/API format: feedback_type, feedback_value, feedback_comment
        | 2. Older CURL/test format: feedback, rating, notes
        |
        | Normalize both formats here so regression tests, frontend actions, and future
        | API consumers can submit feedback without receiving a false validation error.
        */
        $legacyFeedback = $request->input('feedback');

        $feedbackType = $request->input('feedback_type', $legacyFeedback);
        $feedbackType = $this->normalizeFeedbackType($feedbackType);

        $feedbackValue = $request->input('feedback_value', $request->input('rating'));
        $feedbackComment = $request->input('feedback_comment', $request->input('notes'));

        $request->merge([
            'feedback_type' => $feedbackType,
            'feedback_value' => $feedbackValue,
            'feedback_comment' => $feedbackComment,
        ]);

        $validated = $request->validate([
            'feedback_type' => [
                'required',
                'string',
                Rule::in([
                    AIRecommendationFeedback::TYPE_USEFUL,
                    AIRecommendationFeedback::TYPE_NOT_USEFUL,
                    AIRecommendationFeedback::TYPE_TOO_LATE,
                    AIRecommendationFeedback::TYPE_NOT_RELEVANT,
                    AIRecommendationFeedback::TYPE_ACCEPTED,
                    AIRecommendationFeedback::TYPE_DISMISSED,
                    AIRecommendationFeedback::TYPE_COMPLETED,
                    AIRecommendationFeedback::TYPE_RATING,
                ]),
            ],
            'feedback_value' => ['nullable', 'integer', 'min:1', 'max:5'],
            'feedback_comment' => ['nullable', 'string', 'max:2000'],
        ]);

        $feedback = AIRecommendationFeedback::create([
            'recommendation_id' => $recommendation->id,
            'user_id' => $request->user()->id,
            'feedback_type' => $validated['feedback_type'],
            'feedback_value' => $validated['feedback_value'] ?? null,
            'feedback_comment' => $validated['feedback_comment'] ?? null,
            'metadata' => [
                'source' => 'api_feedback_endpoint',
                'payload_format' => $legacyFeedback !== null ? 'legacy_alias' : 'current',
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Recommendation feedback submitted successfully.',
            'data' => [
                'feedback' => $feedback,
            ],
        ], 201);
    }

    private function normalizeFeedbackType(?string $feedbackType): ?string
    {
        if ($feedbackType === null) {
            return null;
        }

        return match (strtolower(trim($feedbackType))) {
            'helpful', 'positive', 'yes', 'like', 'liked' => AIRecommendationFeedback::TYPE_USEFUL,
            'unhelpful', 'not_helpful', 'negative', 'no', 'dislike', 'disliked' => AIRecommendationFeedback::TYPE_NOT_USEFUL,
            'irrelevant' => AIRecommendationFeedback::TYPE_NOT_RELEVANT,
            default => $feedbackType,
        };
    }

    public function dailyScores(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'from_date' => ['nullable', 'date'],
            'to_date' => ['nullable', 'date'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:365'],
            'generate_today' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();

        if (($validated['generate_today'] ?? false) === true) {
            $this->recommendationScoringService->calculateAndStoreForUser($user, now());
        }

        $query = AIUserDailyScore::query()
            ->where('user_id', $user->id)
            ->orderByDesc('score_date');

        if (!empty($validated['from_date'])) {
            $query->whereDate('score_date', '>=', $validated['from_date']);
        }

        if (!empty($validated['to_date'])) {
            $query->whereDate('score_date', '<=', $validated['to_date']);
        }

        $limit = $validated['limit'] ?? 30;

        $scores = $query->limit($limit)->get();

        return response()->json([
            'success' => true,
            'message' => 'AI daily scores retrieved successfully.',
            'data' => [
                'scores' => $scores,
                'latest' => $scores->first(),
                'summary' => [
                    'total' => $scores->count(),
                    'average_life_balance_score' => round((float) $scores->avg('life_balance_score'), 2),
                    'latest_classification' => optional($scores->first())->classification,
                ],
            ],
        ]);
    }

    private function authorizeRecommendationOwner(Request $request, AIRecommendation $recommendation): void
    {
        abort_if(
            $recommendation->user_id !== $request->user()->id,
            403,
            'You are not authorized to access this recommendation.'
        );
    }
}