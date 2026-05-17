<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProductivityCalendarEvent;
use App\Models\ProductivityTask;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class ProductivityCalendarEventController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'view' => ['nullable', Rule::in(['day', 'week', 'month'])],
            'date' => ['nullable', 'date'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'status' => ['nullable', 'string', 'max:50'],
            'event_type' => ['nullable', 'string', 'max:50'],
            'include_tasks' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        $view = $validated['view'] ?? null;
        $date = Carbon::parse($validated['date'] ?? now())->startOfDay();

        [$from, $to] = $this->resolveDateRange($view, $date, $validated);

        $query = ProductivityCalendarEvent::query()
            ->where('user_id', $user->id)
            ->where('start_time', '>=', $from)
            ->where('start_time', '<=', $to)
            ->orderBy('start_time');

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        if (!empty($validated['event_type'])) {
            $query->where('event_type', $validated['event_type']);
        }

        $events = $query->get()->map(fn (ProductivityCalendarEvent $event) => $this->formatEvent($event));

        if ($request->boolean('include_tasks')) {
            $events = $events->merge($this->taskEvents($user->id, $from, $to));
        }

        return response()->json([
            'success' => true,
            'message' => 'Calendar events retrieved successfully.',
            'data' => [
                'view' => $view,
                'date' => $date->toDateString(),
                'from' => $from->toDateTimeString(),
                'to' => $to->toDateTimeString(),
                'events' => $events->sortBy('start_time')->values(),
                'empty_state' => $events->isEmpty(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateEvent($request);

        $event = ProductivityCalendarEvent::create([
            'user_id' => $request->user()->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'event_type' => $validated['event_type'] ?? $validated['type'] ?? 'general',
            'status' => $validated['status'] ?? 'scheduled',
            'start_time' => $validated['start_time'] ?? $validated['start_at'],
            'end_time' => $validated['end_time'] ?? $validated['end_at'] ?? null,
            'location' => $validated['location'] ?? null,
            'metadata' => $this->metadataFromRequest($validated),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Calendar event created successfully.',
            'data' => $this->formatEvent($event),
        ], 201);
    }

    public function show(Request $request, string $event)
    {
        $calendarEvent = $this->findUserEvent($request, $event);

        return response()->json([
            'success' => true,
            'message' => 'Calendar event retrieved successfully.',
            'data' => $this->formatEvent($calendarEvent),
        ]);
    }

    public function update(Request $request, string $event)
    {
        $calendarEvent = $this->findUserEvent($request, $event);
        $validated = $this->validateEvent($request, true);

        $calendarEvent->update([
            'title' => $validated['title'] ?? $calendarEvent->title,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : $calendarEvent->description,
            'event_type' => $validated['event_type'] ?? $validated['type'] ?? $calendarEvent->event_type,
            'status' => $validated['status'] ?? $calendarEvent->status,
            'start_time' => $validated['start_time'] ?? $validated['start_at'] ?? $calendarEvent->start_time,
            'end_time' => $validated['end_time'] ?? $validated['end_at'] ?? $calendarEvent->end_time,
            'location' => array_key_exists('location', $validated) ? $validated['location'] : $calendarEvent->location,
            'metadata' => array_replace($calendarEvent->metadata ?? [], $this->metadataFromRequest($validated)),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Calendar event updated successfully.',
            'data' => $this->formatEvent($calendarEvent->fresh()),
        ]);
    }

    public function destroy(Request $request, string $event)
    {
        $calendarEvent = $this->findUserEvent($request, $event);
        $calendarEvent->delete();

        return response()->json([
            'success' => true,
            'message' => 'Calendar event deleted successfully.',
        ]);
    }

    private function validateEvent(Request $request, bool $isUpdate = false): array
    {
        $titleRule = $isUpdate ? ['sometimes', 'required', 'string', 'max:255'] : ['required', 'string', 'max:255'];
        $startRule = $isUpdate ? ['sometimes', 'required', 'date'] : ['required_without:start_at', 'date'];
        $startAtRule = $isUpdate ? ['sometimes', 'required', 'date'] : ['required_without:start_time', 'date'];

        return $request->validate([
            'title' => $titleRule,
            'description' => ['nullable', 'string'],
            'event_type' => ['nullable', 'string', 'max:50'],
            'type' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['scheduled', 'completed', 'cancelled', 'in_progress'])],
            'start_time' => $startRule,
            'start_at' => $startAtRule,
            'end_time' => ['nullable', 'date', 'after_or_equal:start_time', 'after_or_equal:start_at'],
            'end_at' => ['nullable', 'date', 'after_or_equal:start_time', 'after_or_equal:start_at'],
            'location' => ['nullable', 'string', 'max:255'],
            'reminder_at' => ['nullable', 'date'],
            'color' => ['nullable', 'string', 'max:50'],
        ]);
    }

    private function findUserEvent(Request $request, string $event): ProductivityCalendarEvent
    {
        return ProductivityCalendarEvent::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $event)
            ->firstOrFail();
    }

    private function resolveDateRange(?string $view, Carbon $date, array $validated): array
    {
        if (!empty($validated['from']) && !empty($validated['to'])) {
            return [Carbon::parse($validated['from'])->startOfDay(), Carbon::parse($validated['to'])->endOfDay()];
        }

        return match ($view) {
            'day' => [$date->copy()->startOfDay(), $date->copy()->endOfDay()],
            'week' => [$date->copy()->startOfWeek(), $date->copy()->endOfWeek()],
            'month' => [$date->copy()->startOfMonth(), $date->copy()->endOfMonth()],
            default => [$date->copy()->startOfMonth(), $date->copy()->endOfMonth()],
        };
    }

    private function metadataFromRequest(array $validated): array
    {
        $metadata = [];

        if (array_key_exists('reminder_at', $validated)) {
            $metadata['reminder_at'] = $validated['reminder_at'];
        }

        if (array_key_exists('color', $validated)) {
            $metadata['color'] = $validated['color'];
        }

        return $metadata;
    }

    private function formatEvent(ProductivityCalendarEvent $event): array
    {
        $metadata = $event->metadata ?? [];
        $reminderAt = $metadata['reminder_at'] ?? null;

        return [
            'id' => $event->id,
            'title' => $event->title,
            'description' => $event->description,
            'event_type' => $event->event_type,
            'type' => $event->event_type,
            'status' => $event->status,
            'start_time' => optional($event->start_time)->toDateTimeString(),
            'start_at' => optional($event->start_time)->toDateTimeString(),
            'end_time' => optional($event->end_time)->toDateTimeString(),
            'end_at' => optional($event->end_time)->toDateTimeString(),
            'location' => $event->location,
            'reminder_at' => $reminderAt,
            'has_reminder' => !empty($reminderAt),
            'metadata' => $metadata,
            'source' => 'calendar',
            'created_at' => optional($event->created_at)->toDateTimeString(),
            'updated_at' => optional($event->updated_at)->toDateTimeString(),
        ];
    }

    private function taskEvents(string $userId, Carbon $from, Carbon $to)
    {
        if (!class_exists(ProductivityTask::class) || !Schema::hasTable('productivity_tasks')) {
            return collect();
        }

        return ProductivityTask::query()
            ->where('user_id', $userId)
            ->whereNotNull('due_date')
            ->whereBetween('due_date', [$from->toDateString(), $to->toDateString()])
            ->orderBy('due_date')
            ->get()
            ->map(function (ProductivityTask $task) {
                return [
                    'id' => $task->id,
                    'title' => $task->title,
                    'description' => $task->description ?? null,
                    'event_type' => 'task',
                    'type' => 'task',
                    'status' => $task->status,
                    'priority' => $task->priority ?? null,
                    'start_time' => Carbon::parse($task->due_date)->startOfDay()->toDateTimeString(),
                    'start_at' => Carbon::parse($task->due_date)->startOfDay()->toDateTimeString(),
                    'end_time' => null,
                    'end_at' => null,
                    'location' => null,
                    'reminder_at' => null,
                    'has_reminder' => false,
                    'metadata' => [],
                    'source' => 'task',
                    'due_date' => $task->due_date,
                ];
            });
    }
}
