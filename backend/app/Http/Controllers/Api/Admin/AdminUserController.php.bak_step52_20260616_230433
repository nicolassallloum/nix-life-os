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
use Illuminate\Validation\Rule;
use Spatie\Permission\Models\Role;

class AdminUserController extends Controller
{
    private const ALLOWED_ROLES = ['admin', 'user', 'demo', 'qa'];
    private const ALLOWED_STATUSES = ['active', 'hold', 'inactive'];

    public function index(): JsonResponse
    {
        $users = User::query()
            ->latest()
            ->get()
            ->map(fn (User $user) => $this->formatUser($user));

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
            'email' => ['required', 'email:rfc,dns', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'string', Rule::in(self::ALLOWED_ROLES)],
            'status' => ['required', 'string', Rule::in(self::ALLOWED_STATUSES)],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator);
        }

        try {
            $validated = $validator->validated();

            $user = DB::transaction(function () use ($validated) {
                $role = strtolower($validated['role']);
                $status = strtolower($validated['status']);

                $data = [
                    'name' => $validated['name'],
                    'email' => strtolower($validated['email']),
                    'password' => Hash::make($validated['password']),
                ];

                if (Schema::hasColumn('users', 'role')) {
                    $data['role'] = $role;
                }

                if (Schema::hasColumn('users', 'status')) {
                    $data['status'] = $status;
                }

                if (Schema::hasColumn('users', 'is_active')) {
                    $data['is_active'] = $status === 'active';
                }

                $user = new User();
                $user->forceFill($data);
                $user->save();

                $this->syncSpatieRole($user, $role);

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
            'email' => ['required', 'email:rfc,dns', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8'],
            'role' => ['required', 'string', Rule::in(self::ALLOWED_ROLES)],
            'status' => ['required', 'string', Rule::in(self::ALLOWED_STATUSES)],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator);
        }

        $validated = $validator->validated();

        if ($this->isCurrentUser($user) && strtolower($validated['status']) !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'You cannot hold or deactivate your own admin account.',
                'error' => [
                    'code' => 'SELF_ADMIN_STATUS_CHANGE_BLOCKED',
                ],
            ], 422);
        }

        DB::transaction(function () use ($user, $validated) {
            $role = strtolower($validated['role']);
            $status = strtolower($validated['status']);

            $data = [
                'name' => $validated['name'],
                'email' => strtolower($validated['email']),
            ];

            if (! empty($validated['password'])) {
                $data['password'] = Hash::make($validated['password']);
            }

            if (Schema::hasColumn('users', 'role')) {
                $data['role'] = $role;
            }

            if (Schema::hasColumn('users', 'status')) {
                $data['status'] = $status;
            }

            if (Schema::hasColumn('users', 'is_active')) {
                $data['is_active'] = $status === 'active';
            }

            $user->forceFill($data)->save();
            $this->syncSpatieRole($user->fresh(), $role);
        });

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    public function hold(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ($this->isCurrentUser($user)) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot place your own admin account on hold.',
                'error' => [
                    'code' => 'SELF_ADMIN_HOLD_BLOCKED',
                ],
            ], 422);
        }

        $this->setUserStatus($user, 'hold');
        $user->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'User placed on hold successfully.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    public function activate(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $this->setUserStatus($user, 'active');

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
        return $this->hold($id);
    }

    public function destroy(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ($this->isCurrentUser($user)) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot delete your own admin account.',
                'error' => [
                    'code' => 'SELF_ADMIN_DELETE_BLOCKED',
                ],
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
            return $this->validationError($validator);
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

    private function setUserStatus(User $user, string $status): void
    {
        $status = strtolower($status);
        $isActive = $status === 'active';

        if (Schema::hasColumn('users', 'status') && Schema::hasColumn('users', 'is_active')) {
            DB::statement(
                "UPDATE users
                 SET status = ?,
                     is_active = CASE WHEN ? = 'active' THEN TRUE ELSE FALSE END,
                     updated_at = NOW()
                 WHERE id = ?",
                [$status, $status, $user->id]
            );

            return;
        }

        if (Schema::hasColumn('users', 'status')) {
            DB::statement(
                'UPDATE users SET status = ?, updated_at = NOW() WHERE id = ?',
                [$status, $user->id]
            );

            return;
        }

        if (Schema::hasColumn('users', 'is_active')) {
            DB::statement(
                'UPDATE users SET is_active = ?, updated_at = NOW() WHERE id = ?',
                [$isActive, $user->id]
            );
        }
    }

    private function syncSpatieRole(User $user, string $role): void
    {
        if (! method_exists($user, 'syncRoles')) {
            return;
        }

        try {
            $this->ensureRoleExists($role);
            $user->syncRoles([$role]);
        } catch (\Throwable $e) {
            // Keep user management working even if permission tables are unavailable.
        }
    }

    private function ensureRoleExists(string $role): void
    {
        Role::firstOrCreate([
            'name' => $role,
            'guard_name' => 'web',
        ]);

        Role::firstOrCreate([
            'name' => $role,
            'guard_name' => 'sanctum',
        ]);
    }

    private function formatUser(User $user): array
    {
        $roles = [];

        if (method_exists($user, 'getRoleNames')) {
            try {
                $roles = $user->getRoleNames()->values()->toArray();
            } catch (\Throwable $e) {
                $roles = [];
            }
        }

        $role = strtolower((string) ($user->role ?? ($roles[0] ?? 'user')));
        $status = strtolower((string) ($user->status ?? ''));

        if (! in_array($status, self::ALLOWED_STATUSES, true)) {
            $status = ((bool) ($user->is_active ?? true)) ? 'active' : 'inactive';
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => in_array($role, self::ALLOWED_ROLES, true) ? $role : 'user',
            'roles' => $roles,
            'status' => $status,
            'is_active' => $user->is_active ?? null,
            'last_login_at' => $user->last_login_at ?? null,
            'last_login_ip' => $user->last_login_ip ?? null,
            'failed_login_attempts' => $user->failed_login_attempts ?? 0,
            'last_seen_at' => $user->last_seen_at ?? null,
            'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => optional($user->updated_at)->format('Y-m-d H:i:s'),
        ];
    }

    private function isCurrentUser(User $user): bool
    {
        return (string) auth()->id() === (string) $user->id;
    }

    private function validationError($validator): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Validation failed.',
            'errors' => $validator->errors(),
        ], 422);
    }
}
