<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;

class DemoAccountSeeder extends Seeder
{
    private string $email = 'demo@nixlifeos.com';

    public function run(): void
    {
        DB::transaction(function (): void {
            $now = now();
            $userId = $this->upsertDemoUser($now);

            $this->clearDemoHealthData($userId);
            $this->seedGoals($userId, $now);
            $this->seedSteps($userId, $now);
            $this->seedHydration($userId, $now);
            $this->seedCalories($userId, $now);
            $this->seedWeight($userId, $now);
            $this->seedMedications($userId, $now);
            $this->seedLabTests($userId, $now);
            $this->assignDemoRole($userId);
        });

        $this->command?->info('Demo account seeded successfully: demo@nixlifeos.com / Demo123456');
    }

    private function assignDemoRole(string $userId): void
    {
        Role::firstOrCreate([
            'name' => 'demo',
            'guard_name' => 'web',
        ]);

        $user = User::find($userId);

        if ($user) {
            $user->syncRoles(['demo']);
        }
    }


    private function upsertDemoUser(Carbon $now): string
    {
        $existingUser = DB::table('users')->where('email', $this->email)->first();

        $userId = $existingUser?->id ?? (string) Str::uuid();

        $payload = [
            'id' => $userId,
            'name' => 'Nix Life OS Demo User',
            'email' => $this->email,
            'email_verified_at' => $now,
            'password' => Hash::make('Demo123456'),
            'role' => 'demo',
            'is_active' => true,
            'status' => 'active',
            'phone' => '+96100000000',
            'failed_login_attempts' => 0,
            'updated_at' => $now,
        ];

        if (! $existingUser) {
            $payload['created_at'] = $now;
            DB::table('users')->insert($payload);

            return $userId;
        }

        unset($payload['id']);
        DB::table('users')->where('id', $userId)->update($payload);

        return $userId;
    }

    private function clearDemoHealthData(string $userId): void
    {
        $labTestIds = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->pluck('id');

        if ($labTestIds->isNotEmpty()) {
            DB::table('health_lab_test_results')
                ->whereIn('lab_test_id', $labTestIds)
                ->delete();
        }

        DB::table('health_lab_tests')->where('user_id', $userId)->delete();
        DB::table('health_medications')->where('user_id', $userId)->delete();
        DB::table('health_weight_logs')->where('user_id', $userId)->delete();
        DB::table('health_nutrition_logs')->where('user_id', $userId)->delete();
        DB::table('health_hydration_logs')->where('user_id', $userId)->delete();
        DB::table('health_step_logs')->where('user_id', $userId)->delete();
    }

    private function seedGoals(string $userId, Carbon $now): void
    {
        DB::table('health_user_goals')->updateOrInsert(
            ['user_id' => $userId],
            [
                'daily_steps_goal' => 8000,
                'target_weight_kg' => 59.00,
                'daily_calories_goal' => 1700,
                'daily_water_goal_ml' => 1800,
                'protein_limit_g' => 50.00,
                'carbs_limit_g' => 220.00,
                'fat_limit_g' => 55.00,
                'sugar_limit_g' => 35.00,
                'sodium_limit_mg' => 1000.00,
                'potassium_limit_mg' => 2000.00,
                'phosphorus_limit_mg' => 800.00,
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );
    }

    private function seedSteps(string $userId, Carbon $now): void
    {
        $rows = [];

        for ($i = 13; $i >= 0; $i--) {
            $date = $now->copy()->subDays($i)->toDateString();
            $steps = 5200 + ((13 - $i) * 210);

            $rows[] = [
                'user_id' => $userId,
                'log_date' => $date,
                'steps' => $steps,
                'kilometers' => round($steps * 0.00072, 3),
                'calories_burned' => round($steps * 0.04, 2),
                'source' => 'demo',
                'notes' => 'Demo daily step activity.',
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        DB::table('health_step_logs')->insert($rows);
    }

    private function seedHydration(string $userId, Carbon $now): void
    {
        $rows = [];

        for ($i = 6; $i >= 0; $i--) {
            $date = $now->copy()->subDays($i)->toDateString();

            foreach ([['08:30:00', 350], ['12:30:00', 500], ['17:30:00', 450], ['21:00:00', 300]] as [$time, $amount]) {
                $rows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $userId,
                    'log_date' => $date,
                    'log_time' => $time,
                    'drink_type' => 'water',
                    'amount_ml' => $amount,
                    'hydration_type' => 'water',
                    'quantity_ml' => $amount,
                    'is_ckd_safe' => true,
                    'source' => 'demo',
                    'notes' => 'Demo hydration log.',
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        DB::table('health_hydration_logs')->insert($rows);
    }

    private function seedCalories(string $userId, Carbon $now): void
    {
        $rows = [];
        $foods = [
            ['breakfast', 'Labneh sandwich demo meal', 1, 'serving', 380, 14, 420, 260, 180, 14, 48, 12],
            ['lunch', 'Grilled chicken and rice demo meal', 1, 'plate', 620, 34, 520, 540, 260, 34, 72, 18],
            ['snack', 'Apple demo snack', 1, 'piece', 95, 1, 2, 195, 12, 1, 25, 0],
            ['dinner', 'Vegetable soup demo meal', 1, 'bowl', 310, 10, 390, 480, 140, 10, 46, 8],
        ];

        for ($i = 6; $i >= 0; $i--) {
            $date = $now->copy()->subDays($i)->toDateString();

            foreach ($foods as [$mealType, $foodName, $quantity, $unit, $calories, $protein, $sodium, $potassium, $phosphorus, $proteinG, $carbsG, $fatG]) {
                $rows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $userId,
                    'meal_date' => $date,
                    'meal_type' => $mealType,
                    'food_name' => $foodName,
                    'quantity' => $quantity,
                    'unit' => $unit,
                    'calories' => $calories,
                    'protein' => $protein,
                    'sodium' => $sodium,
                    'potassium' => $potassium,
                    'phosphorus' => $phosphorus,
                    'food_source' => 'demo',
                    'protein_g' => $proteinG,
                    'carbs_g' => $carbsG,
                    'fat_g' => $fatG,
                    'sodium_mg' => $sodium,
                    'potassium_mg' => $potassium,
                    'phosphorus_mg' => $phosphorus,
                    'notes' => 'Demo calorie and nutrition log.',
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        DB::table('health_nutrition_logs')->insert($rows);
    }

    private function seedWeight(string $userId, Carbon $now): void
    {
        $rows = [];

        for ($i = 5; $i >= 0; $i--) {
            $date = $now->copy()->subWeeks($i)->toDateString();
            $weight = 64.8 - ((5 - $i) * 0.25);

            $rows[] = [
                'user_id' => $userId,
                'log_date' => $date,
                'weight_kg' => $weight,
                'body_fat_percentage' => 28.00,
                'muscle_mass_kg' => 42.50,
                'bmi' => round($weight / (1.55 * 1.55), 2),
                'notes' => 'Demo weekly weight tracking.',
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        DB::table('health_weight_logs')->insert($rows);
    }

    private function seedMedications(string $userId, Carbon $now): void
    {
        DB::table('health_medications')->insert([
            [
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'name' => 'Iron Supplement Demo',
                'dosage' => '1 tablet',
                'frequency' => 'Daily',
                'instructions' => 'Take 1 tablet daily at 09:00. Demo medication for testing medication dashboard.',
                'start_date' => $now->copy()->subDays(20)->toDateString(),
                'end_date' => null,
                'is_active' => true,
                'daily_times' => 1,
                'doctor_name' => 'Demo Doctor',
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'name' => 'Vitamin D Demo',
                'dosage' => '1000 IU',
                'frequency' => 'Daily',
                'instructions' => 'Take 1000 IU daily at 13:00. Demo medication for testing active medication list.',
                'start_date' => $now->copy()->subDays(14)->toDateString(),
                'end_date' => null,
                'is_active' => true,
                'daily_times' => 1,
                'doctor_name' => 'Demo Doctor',
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }

    private function seedLabTests(string $userId, Carbon $now): void
    {
        $labTestId = DB::table('health_lab_tests')->insertGetId([
            'user_id' => $userId,
            'test_date' => $now->copy()->subDays(7)->toDateString(),
            'test_name' => 'Kidney Function Demo Panel',
            'category' => 'blood',
            'result_value' => 'Demo panel uploaded',
            'unit' => null,
            'reference_range' => null,
            'lab_name' => 'Nix Demo Lab',
            'doctor_name' => 'Demo Doctor',
            'doctor_notes' => 'Demo values for dashboard testing only.',
            'creatinine' => 2.40,
            'urea' => 78.00,
            'egfr' => 30.00,
            'hemoglobin' => 11.20,
            'sodium' => 139.00,
            'potassium' => 4.80,
            'phosphorus' => 4.20,
            'source_type' => 'demo',
            'status' => 'reviewed',
            'ai_status' => 'completed',
            'is_abnormal' => true,
            'abnormal_reason' => 'Demo CKD monitoring panel.',
            'comparison_status' => 'stable',
            'notes' => 'Demo lab test created by DemoAccountSeeder.',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('health_lab_test_results')->insert([
            [
                'lab_test_id' => $labTestId,
                'test_name' => 'Creatinine',
                'result_value' => '2.40',
                'unit' => 'mg/dL',
                'reference_min' => '0.70',
                'reference_max' => '1.30',
                'reference_text' => 'Demo reference range.',
                'status' => 'high',
                'result_date' => $now->copy()->subDays(7)->toDateString(),
                'doctor_name' => 'Demo Doctor',
                'ai_confidence' => 92.50,
                'user_approved' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'lab_test_id' => $labTestId,
                'test_name' => 'eGFR',
                'result_value' => '30',
                'unit' => 'mL/min/1.73m2',
                'reference_min' => '90',
                'reference_max' => null,
                'reference_text' => 'Demo reference range.',
                'status' => 'low',
                'result_date' => $now->copy()->subDays(7)->toDateString(),
                'doctor_name' => 'Demo Doctor',
                'ai_confidence' => 91.00,
                'user_approved' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }
}
