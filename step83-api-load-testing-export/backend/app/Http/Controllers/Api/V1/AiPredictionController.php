<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiPrediction;
use Illuminate\Http\Request;
use Symfony\Component\Process\Process;

class AiPredictionController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = AiPrediction::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at');

        if ($request->filled('type')) {
            $query->where('prediction_type', $request->type);
        }

        return response()->json([
            'status' => true,
            'data' => $query->limit(50)->get(),
        ]);
    }

    public function latest(Request $request)
    {
        $user = $request->user();

        $weight = AiPrediction::where('user_id', $user->id)
            ->where('prediction_type', 'weight_prediction')
            ->latest()
            ->first();

        $finance = AiPrediction::where('user_id', $user->id)
            ->where('prediction_type', 'financial_forecast')
            ->latest()
            ->first();

        return response()->json([
            'status' => true,
            'data' => [
                'weight_prediction' => $weight,
                'financial_forecast' => $finance,
            ],
        ]);
    }

    public function run(Request $request)
    {
        $request->validate([
            'type' => ['nullable', 'in:weight,finance,all'],
            'days_ahead' => ['nullable', 'integer', 'min:1', 'max:365'],
            'month' => ['nullable', 'date_format:Y-m'],
        ]);

        $user = $request->user();

        $type = $request->input('type', 'all');
        $daysAhead = $request->input('days_ahead', 30);
        $month = $request->input('month');

        $aiEnginePath = base_path('../ai-engine');

        $command = [
            $aiEnginePath . '/venv/bin/python',
            $aiEnginePath . '/run_predictions.py',
            '--user-id=' . $user->id,
            '--type=' . $type,
            '--days-ahead=' . $daysAhead,
        ];

        if ($month) {
            $command[] = '--month=' . $month;
        }

        $process = new Process($command, $aiEnginePath);
        $process->setTimeout(300);
        $process->run();

        if (!$process->isSuccessful()) {
            return response()->json([
                'status' => false,
                'message' => 'Prediction model failed.',
                'error' => $process->getErrorOutput(),
            ], 500);
        }

        return response()->json([
            'status' => true,
            'message' => 'Prediction models executed successfully.',
            'output' => json_decode($process->getOutput(), true),
        ]);
    }
}