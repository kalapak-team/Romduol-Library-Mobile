<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'require_book_approval' => Setting::getBool('require_book_approval', true),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'require_book_approval' => 'required|boolean',
        ]);

        Setting::setValue(
            'require_book_approval',
            $request->boolean('require_book_approval') ? 'true' : 'false'
        );

        return response()->json([
            'message' => 'Settings updated.',
            'require_book_approval' => $request->boolean('require_book_approval'),
        ]);
    }
}
