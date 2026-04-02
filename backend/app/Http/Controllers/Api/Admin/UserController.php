<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $users = User::when($request->search, fn($q) => $q->where('name', 'ilike', "%{$request->search}%")
            ->orWhere('email', 'ilike', "%{$request->search}%"))
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->latest()
            ->paginate(20);

        return UserResource::collection($users);
    }

    public function ban(string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ($user->role === 'admin') {
            return response()->json(['message' => 'Cannot ban an admin.'], 422);
        }

        $user->update(['status' => 'banned']);
        $user->tokens()->delete();

        return response()->json(['message' => 'User banned.']);
    }

    public function unban(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'active']);

        return response()->json(['message' => 'User unbanned.']);
    }

    public function promote(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->update(['role' => 'admin']);

        return response()->json(['message' => 'User promoted to admin.']);
    }

    public function destroy(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'User deleted.']);
    }
}
