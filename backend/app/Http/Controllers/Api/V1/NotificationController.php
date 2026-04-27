<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\LifeNotification;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $query = LifeNotification::where('user_id', $userId)
            ->orderBy('created_at', 'desc');

        if ($request->filled('is_read')) {
            $query->where('is_read', filter_var($request->is_read, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('type')) {
            $query->where('notification_type', $request->type);
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate(20),
        ]);
    }

    public function unreadCount(Request $request, NotificationService $service)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'unread_count' => $service->unreadCount($request->user()->id),
            ],
        ]);
    }

    public function show(Request $request, string $id)
    {
        $notification = LifeNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $notification,
        ]);
    }

    public function markAsRead(Request $request, string $id, NotificationService $service)
    {
        $notification = $service->markAsRead($id, $request->user()->id);

        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read.',
            'data' => $notification,
        ]);
    }

    public function markAllAsRead(Request $request, NotificationService $service)
    {
        $updated = $service->markAllAsRead($request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read.',
            'data' => [
                'updated_count' => $updated,
            ],
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $notification = LifeNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notification deleted.',
        ]);
    }
}