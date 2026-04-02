<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Literature', 'name_km' => 'អក្សរសាស្ត្រ', 'slug' => 'literature', 'icon' => '📖', 'sort_order' => 1],
            ['name' => 'History', 'name_km' => 'ប្រវត្តិសាស្ត្រ', 'slug' => 'history', 'icon' => '🏛️', 'sort_order' => 2],
            ['name' => 'Science', 'name_km' => 'វិទ្យាសាស្ត្រ', 'slug' => 'science', 'icon' => '🔬', 'sort_order' => 3],
            ['name' => 'Buddhism', 'name_km' => 'ព្រះពុទ្ធសាសនា', 'slug' => 'buddhism', 'icon' => '☸️', 'sort_order' => 4],
            ['name' => 'Education', 'name_km' => 'ការអប់រំ', 'slug' => 'education', 'icon' => '🎓', 'sort_order' => 5],
            ['name' => "Children's", 'name_km' => 'សៀវភៅកុមារ', 'slug' => 'children', 'icon' => '🧸', 'sort_order' => 6],
            ['name' => 'Comics', 'name_km' => 'រឿងគំនូរ', 'slug' => 'comics', 'icon' => '🖼️', 'sort_order' => 7],
            ['name' => 'Health', 'name_km' => 'សុខភាព', 'slug' => 'health', 'icon' => '❤️', 'sort_order' => 8],
            ['name' => 'Technology', 'name_km' => 'បច្ចេកវិទ្យា', 'slug' => 'technology', 'icon' => '💻', 'sort_order' => 9],
            ['name' => 'Business', 'name_km' => 'អាជីវកម្ម', 'slug' => 'business', 'icon' => '💼', 'sort_order' => 10],
            ['name' => 'Law', 'name_km' => 'ច្បាប់', 'slug' => 'law', 'icon' => '⚖️', 'sort_order' => 11],
            ['name' => 'Arts & Culture', 'name_km' => 'សិល្បៈ​និង​វប្បធម៌', 'slug' => 'arts', 'icon' => '🎨', 'sort_order' => 12],
        ];

        foreach ($categories as $cat) {
            DB::table('categories')->insert(array_merge($cat, [
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
    }
}
