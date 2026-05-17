<?php

namespace Database\Seeders;

use App\Models\AIRecommendationRule;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AIRecommendationRuleSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            $rules = [
                /*
                |--------------------------------------------------------------------------
                | Finance Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'FIN_BUDGET_001',
                    'rule_name' => 'Monthly Budget Exceeded',
                    'module' => 'finance',
                    'recommendation_type' => 'finance_budget_alert',
                    'condition_key' => 'budget_usage_percentage',
                    'operator' => '>',
                    'threshold_value' => 100,
                    'condition_payload' => [
                        'metric' => 'budget_usage_percentage',
                        'period' => 'monthly',
                        'description' => 'Triggers when user spending exceeds assigned monthly budget.',
                    ],
                    'severity' => 'high',
                    'priority' => 2,
                    'title_template' => 'Budget Exceeded',
                    'message_template' => 'You exceeded your monthly budget for {category_name} by {exceeded_amount}.',
                    'action_template' => 'Review recent transactions and reduce non-essential expenses for the rest of the month.',
                    'base_confidence_score' => 92,
                    'base_impact_score' => 85,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'finance',
                        'risk_type' => 'overspending',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'FIN_BUDGET_002',
                    'rule_name' => 'Budget Usage Near Limit',
                    'module' => 'finance',
                    'recommendation_type' => 'finance_spending_advice',
                    'condition_key' => 'budget_usage_percentage',
                    'operator' => '>=',
                    'threshold_value' => 80,
                    'condition_payload' => [
                        'metric' => 'budget_usage_percentage',
                        'period' => 'monthly',
                        'upper_limit' => 100,
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Budget Near Limit',
                    'message_template' => 'You have used {budget_usage_percentage}% of your {category_name} budget.',
                    'action_template' => 'Monitor your spending carefully before the month ends.',
                    'base_confidence_score' => 88,
                    'base_impact_score' => 70,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'finance',
                        'risk_type' => 'budget_warning',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'FIN_EXPENSE_001',
                    'rule_name' => 'High Expense Ratio',
                    'module' => 'finance',
                    'recommendation_type' => 'finance_spending_advice',
                    'condition_key' => 'expense_income_ratio',
                    'operator' => '>',
                    'threshold_value' => 80,
                    'condition_payload' => [
                        'metric' => 'expense_income_ratio',
                        'period' => 'monthly',
                        'description' => 'Expenses consume more than 80% of income.',
                    ],
                    'severity' => 'high',
                    'priority' => 2,
                    'title_template' => 'High Expense Ratio',
                    'message_template' => 'Your expenses are consuming {expense_income_ratio}% of your income this month.',
                    'action_template' => 'Review recurring expenses and reduce non-essential spending.',
                    'base_confidence_score' => 86,
                    'base_impact_score' => 82,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'finance',
                        'risk_type' => 'cash_flow_pressure',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'FIN_BALANCE_001',
                    'rule_name' => 'Low Account Balance',
                    'module' => 'finance',
                    'recommendation_type' => 'finance_budget_alert',
                    'condition_key' => 'available_balance_percentage',
                    'operator' => '<',
                    'threshold_value' => 20,
                    'condition_payload' => [
                        'metric' => 'available_balance_percentage',
                        'period' => 'current',
                        'description' => 'Available balance is below safe threshold.',
                    ],
                    'severity' => 'critical',
                    'priority' => 1,
                    'title_template' => 'Low Account Balance',
                    'message_template' => 'Your available balance is below the safe threshold.',
                    'action_template' => 'Review upcoming payments and avoid unnecessary spending.',
                    'base_confidence_score' => 90,
                    'base_impact_score' => 90,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'finance',
                        'risk_type' => 'low_balance',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'FIN_SAVINGS_001',
                    'rule_name' => 'No Savings Activity',
                    'module' => 'finance',
                    'recommendation_type' => 'finance_savings_advice',
                    'condition_key' => 'monthly_savings_amount',
                    'operator' => '=',
                    'threshold_value' => 0,
                    'condition_payload' => [
                        'metric' => 'monthly_savings_amount',
                        'period' => 'monthly',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'No Savings Recorded',
                    'message_template' => 'You have not recorded any savings activity this month.',
                    'action_template' => 'Consider allocating a small percentage of your income to savings.',
                    'base_confidence_score' => 78,
                    'base_impact_score' => 65,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'finance',
                        'risk_type' => 'savings_gap',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Health Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'HLTH_STEPS_001',
                    'rule_name' => 'Daily Steps Below Target',
                    'module' => 'health',
                    'recommendation_type' => 'health_activity_advice',
                    'condition_key' => 'daily_steps_percentage',
                    'operator' => '<',
                    'threshold_value' => 50,
                    'condition_payload' => [
                        'metric' => 'daily_steps_percentage',
                        'period' => 'daily',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Low Activity Today',
                    'message_template' => 'Your step count is below 50% of your daily target.',
                    'action_template' => 'Try a short 10 to 15 minute walk today if medically appropriate.',
                    'base_confidence_score' => 82,
                    'base_impact_score' => 68,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'health',
                        'risk_type' => 'low_activity',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'HLTH_HYDRATION_001',
                    'rule_name' => 'Daily Hydration Below Target',
                    'module' => 'health',
                    'recommendation_type' => 'health_hydration_alert',
                    'condition_key' => 'daily_hydration_percentage',
                    'operator' => '<',
                    'threshold_value' => 60,
                    'condition_payload' => [
                        'metric' => 'daily_hydration_percentage',
                        'period' => 'daily',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Hydration Below Target',
                    'message_template' => 'Your hydration is below your daily target.',
                    'action_template' => 'Follow your approved hydration plan and record your next water intake.',
                    'base_confidence_score' => 80,
                    'base_impact_score' => 65,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'health',
                        'risk_type' => 'hydration_gap',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'HLTH_MED_001',
                    'rule_name' => 'Missed Medication Dose',
                    'module' => 'health',
                    'recommendation_type' => 'health_medication_alert',
                    'condition_key' => 'missed_medication_count',
                    'operator' => '>',
                    'threshold_value' => 0,
                    'condition_payload' => [
                        'metric' => 'missed_medication_count',
                        'period' => 'daily',
                    ],
                    'severity' => 'critical',
                    'priority' => 1,
                    'title_template' => 'Medication Reminder',
                    'message_template' => 'You have {missed_medication_count} missed medication dose today.',
                    'action_template' => 'Review your medication schedule and follow your doctor’s instructions.',
                    'base_confidence_score' => 95,
                    'base_impact_score' => 95,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'health',
                        'risk_type' => 'medication_adherence',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'HLTH_WEIGHT_001',
                    'rule_name' => 'Weight Trend Increasing',
                    'module' => 'health',
                    'recommendation_type' => 'health_weight_advice',
                    'condition_key' => 'weight_change_7d_percentage',
                    'operator' => '>',
                    'threshold_value' => 2,
                    'condition_payload' => [
                        'metric' => 'weight_change_7d_percentage',
                        'period' => '7_days',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Weight Trend Increasing',
                    'message_template' => 'Your weight trend increased by {weight_change_7d_percentage}% over the last 7 days.',
                    'action_template' => 'Review nutrition logs, sodium intake, and activity consistency.',
                    'base_confidence_score' => 76,
                    'base_impact_score' => 70,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'health',
                        'risk_type' => 'weight_trend',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'HLTH_NUTRITION_001',
                    'rule_name' => 'Missing Nutrition Logs',
                    'module' => 'health',
                    'recommendation_type' => 'health_nutrition_advice',
                    'condition_key' => 'nutrition_log_count_7d',
                    'operator' => '<',
                    'threshold_value' => 4,
                    'condition_payload' => [
                        'metric' => 'nutrition_log_count_7d',
                        'period' => '7_days',
                    ],
                    'severity' => 'low',
                    'priority' => 4,
                    'title_template' => 'Nutrition Tracking Incomplete',
                    'message_template' => 'You logged meals on fewer than 4 days this week.',
                    'action_template' => 'Try logging at least one main meal per day to improve health insights.',
                    'base_confidence_score' => 72,
                    'base_impact_score' => 55,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'health',
                        'risk_type' => 'nutrition_tracking_gap',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Productivity Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'PROD_TASK_001',
                    'rule_name' => 'Too Many Overdue Tasks',
                    'module' => 'productivity',
                    'recommendation_type' => 'productivity_task_alert',
                    'condition_key' => 'overdue_task_count',
                    'operator' => '>=',
                    'threshold_value' => 3,
                    'condition_payload' => [
                        'metric' => 'overdue_task_count',
                        'period' => 'current',
                    ],
                    'severity' => 'high',
                    'priority' => 2,
                    'title_template' => 'Overdue Tasks Need Attention',
                    'message_template' => 'You have {overdue_task_count} overdue tasks.',
                    'action_template' => 'Start with the highest-priority overdue task and reschedule the rest.',
                    'base_confidence_score' => 94,
                    'base_impact_score' => 82,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'productivity',
                        'risk_type' => 'task_backlog',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'PROD_TASK_002',
                    'rule_name' => 'Low Weekly Task Completion Rate',
                    'module' => 'productivity',
                    'recommendation_type' => 'productivity_task_alert',
                    'condition_key' => 'task_completion_rate_7d',
                    'operator' => '<',
                    'threshold_value' => 50,
                    'condition_payload' => [
                        'metric' => 'task_completion_rate_7d',
                        'period' => '7_days',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Low Task Completion Rate',
                    'message_template' => 'Your task completion rate is below 50% this week.',
                    'action_template' => 'Reduce task load and focus on the top 3 priorities.',
                    'base_confidence_score' => 85,
                    'base_impact_score' => 75,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'productivity',
                        'risk_type' => 'low_completion_rate',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'PROD_CAL_001',
                    'rule_name' => 'Calendar Overload',
                    'module' => 'productivity',
                    'recommendation_type' => 'productivity_schedule_advice',
                    'condition_key' => 'calendar_events_today',
                    'operator' => '>',
                    'threshold_value' => 8,
                    'condition_payload' => [
                        'metric' => 'calendar_events_today',
                        'period' => 'daily',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Schedule Looks Overloaded',
                    'message_template' => 'You have more than 8 calendar events today.',
                    'action_template' => 'Consider rescheduling low-priority items and protecting focus time.',
                    'base_confidence_score' => 82,
                    'base_impact_score' => 72,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'productivity',
                        'risk_type' => 'calendar_overload',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Life Balance Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'BALANCE_SCORE_001',
                    'rule_name' => 'Low Overall Life Balance Score',
                    'module' => 'life_balance',
                    'recommendation_type' => 'life_balance_warning',
                    'condition_key' => 'life_balance_score',
                    'operator' => '<',
                    'threshold_value' => 50,
                    'condition_payload' => [
                        'metric' => 'life_balance_score',
                        'period' => 'daily',
                    ],
                    'severity' => 'critical',
                    'priority' => 1,
                    'title_template' => 'Life Balance Needs Attention',
                    'message_template' => 'Your overall life balance score is below 50.',
                    'action_template' => 'Focus on one small improvement today in your weakest area.',
                    'base_confidence_score' => 88,
                    'base_impact_score' => 92,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'life_balance',
                        'risk_type' => 'overall_balance_risk',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'BALANCE_HEALTH_001',
                    'rule_name' => 'Health Score Lower Than Other Areas',
                    'module' => 'life_balance',
                    'recommendation_type' => 'life_balance_warning',
                    'condition_key' => 'health_score_gap',
                    'operator' => '>',
                    'threshold_value' => 20,
                    'condition_payload' => [
                        'metric' => 'health_score_gap',
                        'comparison' => 'health_vs_average_other_scores',
                        'period' => 'daily',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Health Balance Gap',
                    'message_template' => 'Your health score is lower than your other life areas.',
                    'action_template' => 'Add a simple health action today, such as a short walk, hydration tracking, or meal logging.',
                    'base_confidence_score' => 82,
                    'base_impact_score' => 74,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'life_balance',
                        'risk_type' => 'health_balance_gap',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'BALANCE_BURNOUT_001',
                    'rule_name' => 'Possible Burnout Risk',
                    'module' => 'life_balance',
                    'recommendation_type' => 'life_balance_warning',
                    'condition_key' => 'burnout_risk_score',
                    'operator' => '>',
                    'threshold_value' => 75,
                    'condition_payload' => [
                        'metric' => 'burnout_risk_score',
                        'inputs' => [
                            'overdue_task_count',
                            'calendar_events_today',
                            'low_sleep_score',
                            'low_health_score',
                        ],
                    ],
                    'severity' => 'high',
                    'priority' => 2,
                    'title_template' => 'Possible Burnout Risk',
                    'message_template' => 'Your workload and balance indicators suggest possible burnout risk.',
                    'action_template' => 'Reduce non-critical tasks and schedule recovery time.',
                    'base_confidence_score' => 78,
                    'base_impact_score' => 88,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'life_balance',
                        'risk_type' => 'burnout_risk',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Goals Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'GOAL_PROGRESS_001',
                    'rule_name' => 'Goal Progress Stalled',
                    'module' => 'goals',
                    'recommendation_type' => 'productivity_goal_advice',
                    'condition_key' => 'goal_days_without_update',
                    'operator' => '>=',
                    'threshold_value' => 14,
                    'condition_payload' => [
                        'metric' => 'goal_days_without_update',
                        'period' => 'rolling',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Goal Progress Stalled',
                    'message_template' => 'One of your goals has not been updated for {goal_days_without_update} days.',
                    'action_template' => 'Add a small progress update or break the goal into smaller tasks.',
                    'base_confidence_score' => 84,
                    'base_impact_score' => 72,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'goals',
                        'risk_type' => 'stalled_goal',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'GOAL_DEADLINE_001',
                    'rule_name' => 'Goal Deadline Approaching',
                    'module' => 'goals',
                    'recommendation_type' => 'productivity_goal_advice',
                    'condition_key' => 'goal_days_until_deadline',
                    'operator' => '<=',
                    'threshold_value' => 7,
                    'condition_payload' => [
                        'metric' => 'goal_days_until_deadline',
                        'period' => 'rolling',
                    ],
                    'severity' => 'high',
                    'priority' => 2,
                    'title_template' => 'Goal Deadline Approaching',
                    'message_template' => 'A goal deadline is approaching within 7 days.',
                    'action_template' => 'Review the remaining work and schedule focused time to complete it.',
                    'base_confidence_score' => 88,
                    'base_impact_score' => 80,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'goals',
                        'risk_type' => 'deadline_risk',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Habits Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'HABIT_MISSED_001',
                    'rule_name' => 'Habit Missed Multiple Times',
                    'module' => 'habits',
                    'recommendation_type' => 'productivity_habit_advice',
                    'condition_key' => 'habit_missed_count_7d',
                    'operator' => '>=',
                    'threshold_value' => 3,
                    'condition_payload' => [
                        'metric' => 'habit_missed_count_7d',
                        'period' => '7_days',
                    ],
                    'severity' => 'medium',
                    'priority' => 3,
                    'title_template' => 'Habit Consistency Dropping',
                    'message_template' => 'You missed a habit {habit_missed_count_7d} times this week.',
                    'action_template' => 'Reduce the habit size and make it easier to complete tomorrow.',
                    'base_confidence_score' => 84,
                    'base_impact_score' => 70,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'habits',
                        'risk_type' => 'habit_consistency',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'HABIT_STREAK_001',
                    'rule_name' => 'Habit Streak At Risk',
                    'module' => 'habits',
                    'recommendation_type' => 'productivity_habit_advice',
                    'condition_key' => 'habit_streak_at_risk',
                    'operator' => '=',
                    'threshold_value' => 1,
                    'condition_payload' => [
                        'metric' => 'habit_streak_at_risk',
                        'period' => 'daily',
                    ],
                    'severity' => 'low',
                    'priority' => 4,
                    'title_template' => 'Habit Streak At Risk',
                    'message_template' => 'One of your habit streaks may be interrupted today.',
                    'action_template' => 'Complete the smallest version of the habit to keep your streak alive.',
                    'base_confidence_score' => 76,
                    'base_impact_score' => 60,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'habits',
                        'risk_type' => 'streak_risk',
                        'version' => '1.0',
                    ],
                ],

                /*
                |--------------------------------------------------------------------------
                | Positive Achievement Recommendations
                |--------------------------------------------------------------------------
                */
                [
                    'rule_code' => 'ACHIEVE_BALANCE_001',
                    'rule_name' => 'Excellent Life Balance Achievement',
                    'module' => 'life_balance',
                    'recommendation_type' => 'life_balance_positive',
                    'condition_key' => 'life_balance_score',
                    'operator' => '>=',
                    'threshold_value' => 85,
                    'condition_payload' => [
                        'metric' => 'life_balance_score',
                        'period' => 'daily',
                    ],
                    'severity' => 'positive',
                    'priority' => 5,
                    'title_template' => 'Excellent Life Balance',
                    'message_template' => 'Great work. Your life balance score is excellent today.',
                    'action_template' => 'Keep your current routine and maintain consistency.',
                    'base_confidence_score' => 90,
                    'base_impact_score' => 60,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'achievement',
                        'achievement_type' => 'life_balance',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'ACHIEVE_TASKS_001',
                    'rule_name' => 'All Daily Tasks Completed',
                    'module' => 'productivity',
                    'recommendation_type' => 'system_insight',
                    'condition_key' => 'daily_tasks_completed_percentage',
                    'operator' => '=',
                    'threshold_value' => 100,
                    'condition_payload' => [
                        'metric' => 'daily_tasks_completed_percentage',
                        'period' => 'daily',
                    ],
                    'severity' => 'positive',
                    'priority' => 5,
                    'title_template' => 'Daily Tasks Completed',
                    'message_template' => 'Excellent job. You completed all your planned tasks today.',
                    'action_template' => 'Review what worked well and repeat the same planning approach tomorrow.',
                    'base_confidence_score' => 92,
                    'base_impact_score' => 58,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'achievement',
                        'achievement_type' => 'task_completion',
                        'version' => '1.0',
                    ],
                ],
                [
                    'rule_code' => 'ACHIEVE_HEALTH_001',
                    'rule_name' => 'Health Consistency Achievement',
                    'module' => 'health',
                    'recommendation_type' => 'system_insight',
                    'condition_key' => 'health_consistency_7d',
                    'operator' => '>=',
                    'threshold_value' => 80,
                    'condition_payload' => [
                        'metric' => 'health_consistency_7d',
                        'period' => '7_days',
                    ],
                    'severity' => 'positive',
                    'priority' => 5,
                    'title_template' => 'Strong Health Consistency',
                    'message_template' => 'You maintained strong health tracking consistency this week.',
                    'action_template' => 'Keep your routine stable and continue tracking daily.',
                    'base_confidence_score' => 86,
                    'base_impact_score' => 62,
                    'is_active' => true,
                    'metadata' => [
                        'domain' => 'achievement',
                        'achievement_type' => 'health_consistency',
                        'version' => '1.0',
                    ],
                ],
            ];

            foreach ($rules as $rule) {
                AIRecommendationRule::withTrashed()->updateOrCreate(
                    [
                        'rule_code' => $rule['rule_code'],
                    ],
                    array_merge($rule, [
                        'deleted_at' => null,
                    ])
                );
            }
        });
    }
}