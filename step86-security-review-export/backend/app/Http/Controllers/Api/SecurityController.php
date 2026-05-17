<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class SecurityController extends Controller
{
    public function roles()
    {
        return response()->json([
            'success' => true,
            'message' => 'Roles loaded successfully.',
            'data' => Role::query()
                ->with('permissions')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function permissions()
    {
        return response()->json([
            'success' => true,
            'message' => 'Permissions loaded successfully.',
            'data' => Permission::query()
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function assignRole(Request $request, User $user)
    {
        $validated = $request->validate([
            'role' => ['required', 'string', 'exists:roles,name'],
        ]);

        $user->syncRoles([$validated['role']]);

        return response()->json([
            'success' => true,
            'message' => 'User role updated successfully.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'roles' => $user->getRoleNames()->values(),
                    'permissions' => $user->getAllPermissions()
                        ->pluck('name')
                        ->values(),
                ],
            ],
        ]);
    }
}
