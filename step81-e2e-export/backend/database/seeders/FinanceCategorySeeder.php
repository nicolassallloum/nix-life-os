<?php

namespace Database\Seeders;

use App\Models\AppUser;
use App\Models\FinanceCategory;
use Illuminate\Database\Seeder;

class FinanceCategorySeeder extends Seeder
{
    public function run(): void
    {
        $defaultIncome = [
            ['category_name' => 'Salary', 'category_type' => 'income'],
            ['category_name' => 'Freelance', 'category_type' => 'income'],
            ['category_name' => 'Gift', 'category_type' => 'income'],
        ];

        $defaultExpense = [
            ['category_name' => 'Groceries', 'category_type' => 'expense'],
            ['category_name' => 'Transport', 'category_type' => 'expense'],
            ['category_name' => 'Health', 'category_type' => 'expense'],
            ['category_name' => 'Bills', 'category_type' => 'expense'],
            ['category_name' => 'Shopping', 'category_type' => 'expense'],
        ];

        AppUser::query()->chunk(100, function ($users) use ($defaultIncome, $defaultExpense) {
            foreach ($users as $user) {
                foreach (array_merge($defaultIncome, $defaultExpense) as $category) {
                    FinanceCategory::query()->firstOrCreate([
                        'user_id' => $user->user_id,
                        'category_name' => $category['category_name'],
                        'category_type' => $category['category_type'],
                    ], [
                        'is_system' => true,
                        'is_active' => true,
                    ]);
                }
            }
        });
    }
}