<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;

class AdminUserController extends Controller
{
    public function index(): JsonResponse
    {
        $users = User::query()
            ->latest()
            ->get()
            ->map(fn ($user) => $this->formatUser($user));

        return response()->json([
            'success' => true,
            'message' => 'Users loaded successfully.',
            'data' => [
                'users' => $users,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'string', 'in:ACTIVE,INACTIVE,HOLD'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $validated = $validator->validated();

            $user = DB::transaction(function () use ($validated) {
                $status = $validated['status'] ?? 'ACTIVE';
                $role = $validated['role'] ?? 'user';

                $data = [
                    'name' => $validated['name'],
                    'email' => $validated['email'],
                    'password' => Hash::make($validated['password']),
                ];

                if (Schema::hasColumn('users', 'id')) {
                    $data['id'] = (string) Str::uuid();
                }

                if (Schema::hasColumn('users', 'status')) {
                    $data['status'] = $status === 'HOLD' ? 'INACTIVE' : $status;
                }

                if (Schema::hasColumn('users', 'is_active')) {
                    $data['is_active'] = $status === 'ACTIVE';
                }

                if (Schema::hasColumn('users', 'role')) {
                    $data['role'] = $role;
                }

                $user = new User();
                $user->forceFill($data);
                $user->save();

                if (method_exists($user, 'assignRole')) {
                    try {
                        $this->ensureRoleExists($role);
                        $user->assignRole($role);
                    } catch (\Throwable $roleException) {
                        // Keep user creation successful even if Spatie role assignment fails.
                    }
                }

                return $user->fresh();
            });

            return response()->json([
                'success' => true,
                'message' => 'User created successfully.',
                'data' => [
                    'user' => $this->formatUser($user),
                ],
            ], 201);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'User creation failed.',
                'error' => [
                    'code' => 'USER_CREATE_FAILED',
                    'details' => $e->getMessage(),
                ],
            ], 500);
        }
    }

    public function show(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'User loaded successfully.',
            'data' => [
                'user' => $this->formatUser($user),
            ],
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,' . $user->id],
            'password' => ['nullable', 'string', 'min:8'],
            'role' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'string', 'in:ACTIVE,INACTIVE,HOLD'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();

        DB::transaction(function () use ($user, $validated) {
            $status = $validated['status'] ?? ($user->status ?? 'ACTIVE');
            $role = $validated['role'] ?? ($user->role ?? 'user');

            $data = [
                'name' => $validated['name'],
                'email' => $validated['email'],
            ];

            if (! empty($validated['password'])) {
                $data['password'] = Hash::make($validated['password']);
            }

            if (Schema::hasColumn('users', 'status')) {
                $data['status'] = $status === 'HOLD' ? 'INACTIVE' : $status;
            }

            if (Schema::hasColumn('users', 'is_active')) {
                $data['is_active'] = $status === 'ACTIVE';
            }

            if (Schema::hasColumn('users', 'role')) {
                $data['role'] = $role;
            }

            $user->update($data);

            if (method_exists($user, 'syncRoles')) {
                $this->ensureRoleExists($role);
                $user->syncRoles([$role]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    public function activate(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $data = [];

        if (Schema::hasColumn('users', 'status')) {
            $data['status'] = 'ACTIVE';
        }

        if (Schema::hasColumn('users', 'is_active')) {
            $data['is_active'] = true;
        }

        $user->update($data);

        return response()->json([
            'success' => true,
            'message' => 'User activated successfully.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    public function deactivate(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ((string) auth()->id() === (string) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot hold or deactivate your own account.',
            ], 422);
        }

        $data = [];

        if (Schema::hasColumn('users', 'status')) {
            $data['status'] = 'INACTIVE';
        }

        if (Schema::hasColumn('users', 'is_active')) {
            $data['is_active'] = false;
        }

        $user->update($data);
        $user->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'User placed on hold successfully.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    public function destroy(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ((string) auth()->id() === (string) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot delete your own account.',
            ], 422);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully.',
        ]);
    }

    public function changePassword(Request $request, string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'password' => ['required', 'string', 'min:8'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        $user->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully.',
        ]);
    }

    private function formatUser(User $user): array
    {
        $roles = [];

        if (method_exists($user, 'getRoleNames')) {
            $roles = $user->getRoleNames()->values()->toArray();
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role ?? ($roles[0] ?? 'user'),
            'roles' => $roles,
            'status' => $user->status ?? (($user->is_active ?? true) ? 'ACTIVE' : 'INACTIVE'),
            'is_active' => $user->is_active ?? null,
            'last_login_at' => $user->last_login_at ?? null,
            'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => optional($user->updated_at)->format('Y-m-d H:i:s'),
        ];
    }

    private function ensureRoleExists(string $role): void
    {
        Role::firstOrCreate([
            'name' => $role,
            'guard_name' => 'web',
        ]);
    }
}