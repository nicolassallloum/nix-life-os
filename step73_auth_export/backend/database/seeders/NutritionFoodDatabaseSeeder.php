<?php

namespace Database\Seeders;

use App\Models\NutritionFood;
use App\Models\NutritionFoodAlias;
use App\Models\NutritionFoodCategory;
use App\Models\NutritionFoodServing;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class NutritionFoodDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            'Fruits',
            'Vegetables',
            'Grains',
            'Protein',
            'Dairy',
            'Legumes',
            'Beverages',
            'Prepared Meals',
        ];

        $categoryMap = [];

        foreach ($categories as $categoryName) {
            $category = NutritionFoodCategory::updateOrCreate(
                ['slug' => Str::slug($categoryName)],
                [
                    'name' => $categoryName,
                    'description' => $categoryName . ' category',
                    'is_active' => true,
                ]
            );

            $categoryMap[$categoryName] = $category->id;
        }

        $foods = [
            [
                'category' => 'Protein',
                'food_code' => 'FOOD-CHICKEN-BREAST-100G',
                'name' => 'Chicken Breast, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 165,
                'protein_g' => 31,
                'carbs_g' => 0,
                'fat_g' => 3.6,
                'sodium_mg' => 74,
                'potassium_mg' => 256,
                'phosphorus_mg' => 228,
                'is_ckd_friendly' => false,
                'is_low_sodium' => true,
                'is_low_potassium' => false,
                'is_low_phosphorus' => false,
                'is_low_protein' => false,
                'ckd_warning_level' => 'medium',
                'ckd_notes' => 'High protein and phosphorus. Use limited quantity for CKD diet.',
                'aliases' => ['chicken', 'chicken breast', 'grilled chicken'],
                'servings' => [
                    ['serving_label' => '50 g', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                    ['serving_label' => '1 small piece', 'serving_grams' => 75],
                ],
            ],
            [
                'category' => 'Grains',
                'food_code' => 'FOOD-WHITE-RICE-100G',
                'name' => 'White Rice, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 130,
                'protein_g' => 2.7,
                'carbs_g' => 28,
                'fat_g' => 0.3,
                'sodium_mg' => 1,
                'potassium_mg' => 35,
                'phosphorus_mg' => 43,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'Generally CKD-friendly when portion is controlled.',
                'aliases' => ['rice', 'white rice', 'riz'],
                'servings' => [
                    ['serving_label' => '1/2 cup cooked', 'serving_grams' => 80],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                    ['serving_label' => '1 cup cooked', 'serving_grams' => 160],
                ],
            ],
            [
                'category' => 'Vegetables',
                'food_code' => 'FOOD-CUCUMBER-100G',
                'name' => 'Cucumber, Raw',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 15,
                'protein_g' => 0.7,
                'carbs_g' => 3.6,
                'fat_g' => 0.1,
                'sodium_mg' => 2,
                'potassium_mg' => 147,
                'phosphorus_mg' => 24,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'Good low-calorie CKD-friendly vegetable.',
                'aliases' => ['cucumber', 'khiyar', 'خيار'],
                'servings' => [
                    ['serving_label' => '1/2 cucumber', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
            [
                'category' => 'Fruits',
                'food_code' => 'FOOD-APPLE-100G',
                'name' => 'Apple, Raw',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 52,
                'protein_g' => 0.3,
                'carbs_g' => 14,
                'fat_g' => 0.2,
                'sodium_mg' => 1,
                'potassium_mg' => 107,
                'phosphorus_mg' => 11,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'CKD-friendly fruit when portion is controlled.',
                'aliases' => ['apple', 'تفاح'],
                'servings' => [
                    ['serving_label' => '1 small apple', 'serving_grams' => 120],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
            [
                'category' => 'Legumes',
                'food_code' => 'FOOD-LENTILS-100G',
                'name' => 'Lentils, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 116,
                'protein_g' => 9,
                'carbs_g' => 20,
                'fat_g' => 0.4,
                'sodium_mg' => 2,
                'potassium_mg' => 369,
                'phosphorus_mg' => 180,
                'is_ckd_friendly' => false,
                'is_low_sodium' => true,
                'is_low_potassium' => false,
                'is_low_phosphorus' => false,
                'is_low_protein' => false,
                'ckd_warning_level' => 'high',
                'ckd_notes' => 'High potassium and phosphorus. Use only if approved by dietitian.',
                'aliases' => ['lentils', 'adas', 'عدس'],
                'servings' => [
                    ['serving_label' => '1/4 cup cooked', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
        ];

        foreach ($foods as $item) {
            $food = NutritionFood::updateOrCreate(
                ['food_code' => $item['food_code']],
                [
                    'category_id' => $categoryMap[$item['category']],
                    'name' => $item['name'],
                    'default_serving_label' => $item['default_serving_label'],
                    'default_serving_grams' => $item['default_serving_grams'],

                    'calories' => $item['calories'],
                    'protein_g' => $item['protein_g'],
                    'carbs_g' => $item['carbs_g'],
                    'fat_g' => $item['fat_g'],

                    'sodium_mg' => $item['sodium_mg'],
                    'potassium_mg' => $item['potassium_mg'],
                    'phosphorus_mg' => $item['phosphorus_mg'],

                    'is_ckd_friendly' => $item['is_ckd_friendly'],
                    'is_low_sodium' => $item['is_low_sodium'],
                    'is_low_potassium' => $item['is_low_potassium'],
                    'is_low_phosphorus' => $item['is_low_phosphorus'],
                    'is_low_protein' => $item['is_low_protein'],

                    'ckd_warning_level' => $item['ckd_warning_level'],
                    'ckd_notes' => $item['ckd_notes'],
                    'source' => 'manual',
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );

            foreach ($item['aliases'] as $alias) {
                NutritionFoodAlias::updateOrCreate(
                    [
                        'food_id' => $food->id,
                        'alias_name' => $alias,
                    ],
                    [
                        'language_code' => 'en',
                    ]
                );
            }

            foreach ($item['servings'] as $index => $serving) {
                $ratio = $serving['serving_grams'] / $item['default_serving_grams'];

                NutritionFoodServing::updateOrCreate(
                    [
                        'food_id' => $food->id,
                        'serving_label' => $serving['serving_label'],
                    ],
                    [
                        'serving_grams' => $serving['serving_grams'],

                        'calories' => round($item['calories'] * $ratio, 2),
                        'protein_g' => round($item['protein_g'] * $ratio, 2),
                        'carbs_g' => round($item['carbs_g'] * $ratio, 2),
                        'fat_g' => round($item['fat_g'] * $ratio, 2),

                        'sodium_mg' => round($item['sodium_mg'] * $ratio, 2),
                        'potassium_mg' => round($item['potassium_mg'] * $ratio, 2),
                        'phosphorus_mg' => round($item['phosphorus_mg'] * $ratio, 2),

                        'is_default' => $serving['serving_grams'] == $item['default_serving_grams'],
                        'display_order' => $index + 1,
                    ]
                );
            }
        }
    }
}