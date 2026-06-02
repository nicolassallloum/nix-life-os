<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminDashboardController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        if (! $this->isAllowedAdmin($request)) {
            return response()->json([
                'success' => false,
                'message' => 'This admin dashboard is available only for admin@nixlifeos.com.',
            ], 403);
        }

        $today = now()->startOfDay();
        $onlineCutoff = now()->subMinutes(5);

        $totalUsers = $this->tableCount('users');
        $activeUsers = $this->tableCount('users', function ($query) {
            if (Schema::hasColumn('users', 'is_active')) {
                $query->where('is_active', true);
            } elseif (Schema::hasColumn('users', 'status')) {
                $query->whereIn('status', ['ACTIVE', 'active']);
            }
        });

        $onlineUsers = 0;
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'last_seen_at')) {
            $onlineUsers = DB::table('users')->where('last_seen_at', '>=', $onlineCutoff)->count();
        }

        $totalLogins = 0;
        $todayLogins = 0;
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'last_login_at')) {
            $totalLogins = DB::table('users')->whereNotNull('last_login_at')->count();
            $todayLogins = DB::table('users')->where('last_login_at', '>=', $today)->count();
        }

        $failedLoginAttempts = 0;
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'failed_login_attempts')) {
            $failedLoginAttempts = (int) DB::table('users')->sum('failed_login_attempts');
        }

        $applicationVisits = $this->tableCount('application_visits');
        $todayVisits = 0;
        if (Schema::hasTable('application_visits') && Schema::hasColumn('application_visits', 'visited_at')) {
            $todayVisits = DB::table('application_visits')->where('visited_at', '>=', $today)->count();
        }

        $financeTotals = $this->financeTotals();

        return response()->json([
            'success' => true,
            'message' => 'Admin dashboard summary loaded successfully.',
            'data' => [
                'users' => [
                    'total_users' => $totalUsers,
                    'active_users' => $activeUsers,
                    'online_users' => $onlineUsers,
                    'total_logins' => $totalLogins,
                    'today_logins' => $todayLogins,
                    'failed_login_attempts' => $failedLoginAttempts,
                ],
                'application' => [
                    'total_visits' => $applicationVisits,
                    'today_visits' => $todayVisits,
                    'most_used_pages' => $this->mostUsedPages(),
                ],
                'finance' => $financeTotals,
                'recent_users' => $this->recentUsers(),
                'generated_at' => now()->toDateTimeString(),
            ],
        ]);
    }

    private function financeTotals(): array
    {
        if (! Schema::hasTable('finance_transactions')) {
            return [
                'total_transactions' => 0,
                'total_income' => 0,
                'total_expenses' => 0,
                'total_transfers' => 0,
                'total_accounts' => 0,
                'total_budgets' => 0,
                'total_categories' => 0,
            ];
        }

        return [
            'total_transactions' => DB::table('finance_transactions')->count(),
            'total_income' => (float) DB::table('finance_transactions')->where('transaction_type', 'income')->sum('amount'),
            'total_expenses' => (float) DB::table('finance_transactions')->where('transaction_type', 'expense')->sum('amount'),
            'total_transfers' => (float) DB::table('finance_transactions')->where('transaction_type', 'transfer')->sum('amount'),
            'total_accounts' => $this->tableCount('finance_accounts'),
            'total_budgets' => $this->tableCount('finance_budgets'),
            'total_categories' => $this->categoryCount(),
        ];
    }

    private function recentUsers(): array
    {
        if (! Schema::hasTable('users')) {
            return [];
        }

        return DB::table('users')
            ->select(array_values(array_filter([
                Schema::hasColumn('users', 'id') ? 'id' : null,
                Schema::hasColumn('users', 'name') ? 'name' : null,
                Schema::hasColumn('users', 'email') ? 'email' : null,
                Schema::hasColumn('users', 'status') ? 'status' : null,
                Schema::hasColumn('users', 'last_login_at') ? 'last_login_at' : null,
                Schema::hasColumn('users', 'created_at') ? 'created_at' : null,
            ])))
            ->orderByDesc(Schema::hasColumn('users', 'created_at') ? 'created_at' : 'id')
            ->limit(10)
            ->get()
            ->toArray();
    }

    private function mostUsedPages(): array
    {
        if (! Schema::hasTable('application_visits') || ! Schema::hasColumn('application_visits', 'page_url')) {
            return [];
        }

        return DB::table('application_visits')
            ->select('page_url', DB::raw('COUNT(*) as visits'))
            ->groupBy('page_url')
            ->orderByDesc('visits')
            ->limit(10)
            ->get()
            ->toArray();
    }

    private function categoryCount(): int
    {
        if (Schema::hasTable('finance_categories')) {
            return DB::table('finance_categories')->count();
        }

        if (Schema::hasTable('nix_life_os.finance_category')) {
            return DB::table('nix_life_os.finance_category')->count();
        }

        return 0;
    }

    private function tableCount(string $table, ?callable $callback = null): int
    {
        if (! Schema::hasTable($table)) {
            return 0;
        }

        $query = DB::table($table);

        if ($callback) {
            $callback($query);
        }

        return $query->count();
    }

    private function isAllowedAdmin(Request $request): bool
    {
        return strtolower((string) optional($request->user())->email) === 'admin@nixlifeos.com';
    }
}
