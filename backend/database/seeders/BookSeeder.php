<?php

namespace Database\Seeders;

use App\Models\Book;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Seeder;

class BookSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();
        $uploader = User::where('username', 'sokha_chan')->first() ?? $admin;
        $categories = Category::all()->keyBy('slug');

        $books = [
            [
                'title' => 'Tum Teav',
                'title_km' => 'តុម​តាវ',
                'author' => 'Santhor Mok',
                'language' => 'km',
                'category_slug' => 'literature',
                'description' => 'A classic Khmer love story set in the Angkor era.',
            ],
            [
                'title' => 'The History of Khmer Empire',
                'title_km' => 'ប្រវត្តិចក្រភពខ្មែរ',
                'author' => 'Chheng Phon',
                'language' => 'km',
                'category_slug' => 'history',
                'description' => 'Comprehensive account of the Khmer Empire from 802 to 1431 CE.',
            ],
            [
                'title' => 'Buddhist Teachings for Daily Life',
                'title_km' => 'ព្រះធម៌សម្រាប់ជីវិតប្រចាំថ្ងៃ',
                'author' => 'Ven. Khy Sovanratana',
                'language' => 'km',
                'category_slug' => 'buddhism',
                'description' => 'Practical Buddhist wisdom for modern Khmer life.',
            ],
            [
                'title' => 'Introduction to Computer Science',
                'title_km' => 'វិទ្យាសាស្ត្រកុំព្យូទ័រ',
                'author' => 'Prak Sothea',
                'language' => 'km',
                'category_slug' => 'technology',
                'description' => 'Entry-level computer science textbook in Khmer.',
            ],
            [
                'title' => 'Khmer Cuisine Secrets',
                'title_km' => 'អាហារខ្មែរប្រពៃណី',
                'author' => 'Sovan Ly',
                'language' => 'km',
                'category_slug' => 'arts',
                'description' => 'Recipes and stories behind traditional Cambodian dishes.',
            ],
            [
                'title' => 'Cambodia Business Law',
                'title_km' => 'ច្បាប់អាជីវកម្មកម្ពុជា',
                'author' => 'Chea Sopheak',
                'language' => 'km',
                'category_slug' => 'law',
                'description' => 'Essential guide to commercial law in Cambodia.',
            ],
            [
                'title' => 'Little Stars — Children Stories',
                'title_km' => 'ផ្កាយតូចៗ',
                'author' => 'Meas Kolap',
                'language' => 'km',
                'category_slug' => 'children',
                'description' => 'A collection of moral stories for young Khmer children.',
            ],
            [
                'title' => 'Health and Wellness in Cambodia',
                'title_km' => 'សុខភាព​និង​សុខុមាលភាព',
                'author' => 'Dr. Heng Borin',
                'language' => 'km',
                'category_slug' => 'health',
                'description' => 'Traditional and modern healthcare practices for Cambodians.',
            ],
            [
                'title' => 'Khmer Grammar Guide',
                'title_km' => 'ការណែនាំអំពីវេយ្យាករណ៍ខ្មែរ',
                'author' => 'Kim Sitha',
                'language' => 'km',
                'category_slug' => 'education',
                'description' => 'Comprehensive Khmer language grammar reference.',
            ],
            [
                'title' => 'Rice: The Heart of Cambodia',
                'title_km' => 'ស្រូវ​ — ចិត្តនៃកម្ពុជា',
                'author' => 'Ouk Sokha',
                'language' => 'en',
                'category_slug' => 'history',
                'description' => 'Exploration of rice cultivation and its cultural significance in Cambodia.',
            ],
        ];

        foreach ($books as $b) {
            $catId = $categories->get($b['category_slug'])?->id;
            unset($b['category_slug']);

            Book::create(array_merge($b, [
                'uploader_id' => $uploader->id,
                'category_id' => $catId,
                'file_url' => null,
                'file_type' => 'pdf',
                'file_size' => 1024 * 512,
                'status' => 'approved',
                'is_featured' => in_array($b['title'], ['Tum Teav', 'The History of Khmer Empire'], true),
            ]));
        }
    }
}
