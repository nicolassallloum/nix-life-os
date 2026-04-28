<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasPermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        if (! $user->hasPermissionTo($permission, 'web')) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Missing permission: ' . $permission,
            ], 403);
        }

        return $next($request);
    }
}
