<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthAlert;
use App\Services\Health\HealthAlertEngineService;
use Illuminate\Http\Request;

class HealthAlertController extends Controller
{
    public function index(Request $request)
    {
        $query = HealthAlert::where('user_id', $request->user()->id)
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        return response()->json([
            'success' => true,
            'message' => 'Health alerts loaded successfully.',
            'data' => $query->paginate(20),
        ]);
    }

    public function summary(Request $request)
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Health alerts summary loaded successfully.',
            'data' => [
                'active_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->count(),
                'critical_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->where('severity', 'critical')->count(),
                'warning_count' => HealthAlert::where('user_id', $userId)->where('status', 'active')->where('severity', 'warning')->count(),
                'unread_count' => HealthAlert::where('user_id', $userId)->whereNull('read_at')->count(),
                'latest' => HealthAlert::where('user_id', $userId)->latest()->limit(5)->get(),
            ],
        ]);
    }

    public function run(Request $request, HealthAlertEngineService $engine)
    {
        $alerts = $engine->runForUser(
            $request->user()->id,
            $request->input('date')
        );

        return response()->json([
            'success' => true,
            'message' => 'Health alerts engine executed successfully.',
            'data' => [
                'generated_count' => count($alerts),
                'alerts' => array_values($alerts),
            ],
        ]);
    }

    public function markAsRead(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => $alert->status === 'active' ? 'read' : $alert->status,
            'read_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert marked as read.',
            'data' => $alert,
        ]);
    }

    public function resolve(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => 'resolved',
            'resolved_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert resolved successfully.',
            'data' => $alert,
        ]);
    }

    public function dismiss(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->update([
            'status' => 'dismissed',
            'dismissed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert dismissed successfully.',
            'data' => $alert,
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $alert = HealthAlert::where('user_id', $request->user()->id)->findOrFail($id);

        $alert->delete();

        return response()->json([
            'success' => true,
            'message' => 'Alert deleted successfully.',
        ]);
    }
}