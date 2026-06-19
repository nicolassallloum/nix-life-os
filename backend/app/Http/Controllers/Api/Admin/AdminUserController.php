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
    private array $schemaTableCache = [];

    private array $schemaColumnCache = [];

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

    public function dashboard(Request $request, string $id): JsonResponse
    {
        try {
            $user = DB::table('users')->where('id', $id)->first();

            if (! $user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found.',
                ], 404);
            }

            $today = now()->toDateString();

            return response()->json([
                'success' => true,
                'message' => 'User finance and health dashboard loaded successfully.',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name ?? null,
                        'email' => $user->email ?? null,
                        'role' => $user->role ?? null,
                        'status' => $user->status ?? null,
                        'created_at' => $user->created_at ?? null,
                        'last_login_at' => $user->last_login_at ?? null,
                    ],
                    'finance' => $this->userFinanceDashboard($id),
                    'health' => $this->userHealthDashboard($id, $today),
                    'generated_at' => now()->toDateTimeString(),
                ],
            ]);
        } catch (\Throwable $e) {
            \Log::error('Admin user dashboard failed', [
                'user_id' => $id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'User dashboard failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    private function userFinanceDashboard(string $userId): array
    {
        $accounts = $this->countRows('finance_accounts', $userId);
        $transactions = $this->countRows('finance_transactions', $userId);
        $budgets = $this->countRows('finance_budgets', $userId);
        $categories = $this->countRows('finance_categories', $userId);

        $totalBalance = $this->sumRows('finance_accounts', $userId, 'current_balance');

        $income = 0.0;
        $expenses = 0.0;
        $transfers = 0.0;

        if ($this->hasTable('finance_transactions')) {
            $income = (float) DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'income')
                ->sum('amount');

            $expenses = (float) DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'expense')
                ->sum('amount');

            $transfers = (float) DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->where('transaction_type', 'transfer')
                ->sum('amount');
        }

        return [
            'summary' => [
                'accounts_count' => $accounts,
                'transactions_count' => $transactions,
                'budgets_count' => $budgets,
                'categories_count' => $categories,
                'total_balance' => round($totalBalance, 2),
                'total_income' => round($income, 2),
                'total_expenses' => round($expenses, 2),
                'total_transfers' => round($transfers, 2),
                'net_total' => round($income - $expenses, 2),
            ],
            'recent_accounts' => $this->recentRows('finance_accounts', $userId, 5),
            'recent_transactions' => $this->recentRows('finance_transactions', $userId, 8),
        ];
    }

    private function userHealthDashboard(string $userId, string $today): array
    {
        $todaySteps = 0;
        if ($this->hasTable('health_step_logs')) {
            $todaySteps = (int) DB::table('health_step_logs')
                ->where('user_id', $userId)
                ->whereDate('log_date', $today)
                ->sum('steps');
        }

        $todayWater = 0;
        if ($this->hasTable('health_hydration_logs')) {
            $hydrationColumn = $this->hasColumn('health_hydration_logs', 'quantity_ml') ? 'quantity_ml' : 'amount_ml';
            $dateColumn = $this->hasColumn('health_hydration_logs', 'log_date') ? 'log_date' : 'created_at';

            $todayWater = (int) DB::table('health_hydration_logs')
                ->where('user_id', $userId)
                ->whereDate($dateColumn, $today)
                ->sum($hydrationColumn);
        }

        $todayCalories = 0;
        $todayProtein = 0;
        $todaySodium = 0;
        $todayPotassium = 0;
        $todayPhosphorus = 0;

        if ($this->hasTable('health_nutrition_logs')) {
            $dateColumn = $this->hasColumn('health_nutrition_logs', 'meal_date') ? 'meal_date' : 'created_at';

            $base = DB::table('health_nutrition_logs')
                ->where('user_id', $userId)
                ->whereDate($dateColumn, $today);

            $todayCalories = (float) (clone $base)->sum('calories');
            $todayProtein = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'protein_g') ? 'protein_g' : 'protein');
            $todaySodium = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'sodium_mg') ? 'sodium_mg' : 'sodium');
            $todayPotassium = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'potassium_mg') ? 'potassium_mg' : 'potassium');
            $todayPhosphorus = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'phosphorus_mg') ? 'phosphorus_mg' : 'phosphorus');
        }

        $currentWeight = null;
        $currentBmi = null;
        if ($this->hasTable('health_weight_logs')) {
            $weight = DB::table('health_weight_logs')
                ->where('user_id', $userId)
                ->orderByDesc($this->hasColumn('health_weight_logs', 'log_date') ? 'log_date' : 'created_at')
                ->first();

            $currentWeight = $weight?->weight_kg !== null ? (float) $weight->weight_kg : null;
            $currentBmi = $weight?->bmi !== null ? (float) $weight->bmi : null;
        }

        $lastSleepHours = null;
        if ($this->hasTable('health_sleep_logs')) {
            $sleep = DB::table('health_sleep_logs')
                ->where('user_id', $userId)
                ->orderByDesc('sleep_date')
                ->orderByDesc('created_at')
                ->first();

            if ($sleep) {
                $lastSleepHours = $sleep->duration_hours !== null
                    ? (float) $sleep->duration_hours
                    : round(((int) ($sleep->duration_minutes ?? 0)) / 60, 2);
            }
        }

        $todayMood = null;
        if ($this->hasTable('health_mood_logs')) {
            $todayMood = DB::table('health_mood_logs')
                ->where('user_id', $userId)
                ->whereDate('mood_date', $today)
                ->orderByDesc('updated_at')
                ->value('mood_label');
        }

        $activeMedications = 0;
        if ($this->hasTable('health_medications')) {
            $activeMedications = DB::table('health_medications')
                ->where('user_id', $userId)
                ->where('status', 'active')
                ->count();
        }

        return [
            'summary' => [
                'today_steps' => $todaySteps,
                'today_water_ml' => $todayWater,
                'today_calories' => round($todayCalories, 2),
                'today_protein_g' => round($todayProtein, 2),
                'today_sodium_mg' => round($todaySodium, 2),
                'today_potassium_mg' => round($todayPotassium, 2),
                'today_phosphorus_mg' => round($todayPhosphorus, 2),
                'current_weight_kg' => $currentWeight,
                'current_bmi' => $currentBmi,
                'last_sleep_hours' => $lastSleepHours,
                'today_mood' => $todayMood,
                'active_medications' => $activeMedications,
                'lab_tests_count' => $this->countRows('health_lab_tests', $userId),
                'active_alerts_count' => $this->countRowsWhere('health_alerts', $userId, 'status', 'active'),
            ],
            'counts' => [
                'step_logs' => $this->countRows('health_step_logs', $userId),
                'hydration_logs' => $this->countRows('health_hydration_logs', $userId),
                'nutrition_logs' => $this->countRows('health_nutrition_logs', $userId),
                'weight_logs' => $this->countRows('health_weight_logs', $userId),
                'sleep_logs' => $this->countRows('health_sleep_logs', $userId),
                'mood_logs' => $this->countRows('health_mood_logs', $userId),
                'medications' => $this->countRows('health_medications', $userId),
                'lab_tests' => $this->countRows('health_lab_tests', $userId),
                'alerts' => $this->countRows('health_alerts', $userId),
            ],
            'recent_steps' => $this->recentRows('health_step_logs', $userId, 5),
            'recent_nutrition' => $this->recentRows('health_nutrition_logs', $userId, 5),
            'recent_weight' => $this->recentRows('health_weight_logs', $userId, 5),
            'recent_sleep' => $this->recentRows('health_sleep_logs', $userId, 5),
            'recent_mood' => $this->recentRows('health_mood_logs', $userId, 5),
            'recent_medications' => $this->recentRows('health_medications', $userId, 5),
            'recent_lab_tests' => $this->recentRows('health_lab_tests', $userId, 5),
            'recent_alerts' => $this->recentRows('health_alerts', $userId, 5),
        ];
    }

    private function countRows(string $table, string $userId): int
    {
        if (! $this->hasTable($table) || ! $this->hasColumn($table, 'user_id')) {
            return 0;
        }

        return DB::table($table)->where('user_id', $userId)->count();
    }

    private function countRowsWhere(string $table, string $userId, string $column, mixed $value): int
    {
        if (! $this->hasTable($table) || ! $this->hasColumn($table, 'user_id') || ! $this->hasColumn($table, $column)) {
            return 0;
        }

        return DB::table($table)->where('user_id', $userId)->where($column, $value)->count();
    }

    private function sumRows(string $table, string $userId, string $column): float
    {
        if (! $this->hasTable($table) || ! $this->hasColumn($table, 'user_id') || ! $this->hasColumn($table, $column)) {
            return 0.0;
        }

        return (float) DB::table($table)->where('user_id', $userId)->sum($column);
    }

    private function recentRows(string $table, string $userId, int $limit = 5): array
    {
        if (! $this->hasTable($table) || ! $this->hasColumn($table, 'user_id')) {
            return [];
        }

        $orderColumn = $this->hasColumn($table, 'updated_at')
            ? 'updated_at'
            : ($this->hasColumn($table, 'created_at') ? 'created_at' : 'id');

        return DB::table($table)
            ->where('user_id', $userId)
            ->orderByDesc($orderColumn)
            ->limit($limit)
            ->get()
            ->map(fn ($row) => (array) $row)
            ->toArray();
    }

    private function hasTable(string $table): bool
    {
        return $this->schemaTableCache[$table] ??= Schema::hasTable($table);
    }

    private function hasColumn(string $table, string $column): bool
    {
        $key = $table . '.' . $column;

        return $this->schemaColumnCache[$key] ??= Schema::hasColumn($table, $column);
    }


}
