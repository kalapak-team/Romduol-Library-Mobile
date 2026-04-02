<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin
        User::create([
            'name' => 'Admin',
            'name_km' => 'អ្នកគ្រប់គ្រង',
            'username' => 'admin',
            'email' => 'admin@romduol.lib',
            'password' => Hash::make('Admin@1234'),
            'role' => 'admin',
            'status' => 'active',
        ]);

        // Sample users
        $users = [
            ['name' => 'Sokha Chan', 'name_km' => 'សុខា ចាន់', 'username' => 'sokha_chan', 'email' => 'sokha@example.com'],
            ['name' => 'Dara Keo', 'name_km' => 'ដារា កែវ', 'username' => 'dara_keo', 'email' => 'dara@example.com'],
            ['name' => 'Pich Srey', 'name_km' => 'ពេជ្រ ស្រី', 'username' => 'pich_srey', 'email' => 'pich@example.com'],
            ['name' => 'Vireak Lim', 'name_km' => 'វិរៈ លីម', 'username' => 'vireak_lim', 'email' => 'vireak@example.com'],
            ['name' => 'Bopha Meas', 'name_km' => 'បុប្ផា មាស', 'username' => 'bopha_meas', 'email' => 'bopha@example.com'],
        ];

        foreach ($users as $u) {
            User::create(array_merge($u, [
                'password' => Hash::make('Password@123'),
                'role' => 'user',
                'status' => 'active',
            ]));
        }
    }
}
