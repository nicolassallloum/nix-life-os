<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'status' => 401,
                ],
            ], 401);
        }

        $role = strtolower((string) ($user->role ?? ''));
        $status = strtolower((string) ($user->status ?? ''));

        $hasAdminRole = $role === 'admin';

        if (! $hasAdminRole && method_exists($user, 'hasRole')) {
            try {
                $hasAdminRole = $user->hasRole('admin');
            } catch (\Throwable $e) {
                $hasAdminRole = false;
            }
        }

        $isActive = true;

        if (isset($user->is_active)) {
            $isActive = (bool) $user->is_active;
        }

        if ($status !== '' && ! in_array($status, ['active'], true)) {
            $isActive = false;
        }

        if (! $hasAdminRole || ! $isActive) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden. Admin access is required.',
                'error' => [
                    'code' => 'ADMIN_ACCESS_REQUIRED',
                    'status' => 403,
                ],
            ], 403);
        }

        return $next($request);
    }
}
