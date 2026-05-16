<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'code' => 'free',
                'name' => 'Free',
                'monthly_price' => 0,
                'yearly_price' => 0,
                'max_finance_accounts' => 2,
                'max_projects' => 2,
                'max_ai_insights_per_month' => 5,
                'max_notifications_per_month' => 20,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => false,
                'automation_module_enabled' => false,
                'monitoring_module_enabled' => false,
                'features' => [
                    'Basic finance tracking',
                    'Basic health tracking',
                    'Basic project tracking',
                ],
                'is_active' => true,
            ],
            [
                'code' => 'pro',
                'name' => 'Pro',
                'monthly_price' => 9.99,
                'yearly_price' => 99.99,
                'max_finance_accounts' => 20,
                'max_projects' => 50,
                'max_ai_insights_per_month' => 300,
                'max_notifications_per_month' => 1000,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => true,
                'automation_module_enabled' => true,
                'monitoring_module_enabled' => true,
                'features' => [
                    'Advanced finance analytics',
                    'AI insights',
                    'Automation engine',
                    'Monitoring dashboard',
                    'Unlimited dashboards',
                ],
                'is_active' => true,
            ],
            [
                'code' => 'enterprise',
                'name' => 'Enterprise',
                'monthly_price' => 49.99,
                'yearly_price' => 499.99,
                'max_finance_accounts' => 999999,
                'max_projects' => 999999,
                'max_ai_insights_per_month' => 999999,
                'max_notifications_per_month' => 999999,
                'finance_module_enabled' => true,
                'health_module_enabled' => true,
                'projects_module_enabled' => true,
                'ai_module_enabled' => true,
                'automation_module_enabled' => true,
                'monitoring_module_enabled' => true,
                'features' => [
                    'Enterprise usage',
                    'Team support ready',
                    'Advanced monitoring',
                    'Priority support',
                    'Custom integrations',
                ],
                'is_active' => true,
            ],
        ];

        foreach ($plans as $plan) {
            Plan::updateOrCreate(
                ['code' => $plan['code']],
                $plan
            );
        }
    }
}