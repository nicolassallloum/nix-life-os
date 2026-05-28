<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminDashboardController extends Controller
{
    public function summary()
    {
        return response()->json([
            'success' => true,
            'message' => 'Admin dashboard summary loaded successfully.',
            'data' => [
                'users' => [
                    'total' => User::count(),
                    'active' => Schema::hasColumn('users', 'status')
                        ? User::where('status', 'ACTIVE')->count()
                        : User::count(),
                    'inactive' => Schema::hasColumn('users', 'status')
                        ? User::where('status', 'INACTIVE')->count()
                        : 0,
                    'today_logins' => Schema::hasColumn('users', 'last_login_at')
                        ? User::whereDate('last_login_at', now()->toDateString())->count()
                        : 0,
                ],

                'website_usage' => [
                    'visits_today' => Schema::hasTable('website_usage_logs')
                        ? DB::table('website_usage_logs')->whereDate('created_at', now()->toDateString())->count()
                        : 0,
                    'api_requests_today' => Schema::hasTable('website_usage_logs')
                        ? DB::table('website_usage_logs')
                            ->whereDate('created_at', now()->toDateString())
                            ->whereNotNull('endpoint')
                            ->count()
                        : 0,
                ],

                'application_data' => [
                    'finance_accounts' => Schema::hasTable('finance_accounts')
                        ? DB::table('finance_accounts')->count()
                        : 0,
                    'finance_transactions' => Schema::hasTable('finance_transactions')
                        ? DB::table('finance_transactions')->count()
                        : 0,
                    'finance_budgets' => Schema::hasTable('finance_budgets')
                        ? DB::table('finance_budgets')->count()
                        : 0,
                    'notifications' => Schema::hasTable('notifications')
                        ? DB::table('notifications')->count()
                        : 0,
                ],
            ],
        ]);
    }
}
