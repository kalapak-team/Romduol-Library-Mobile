<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookResource;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function show(string $username): JsonResponse
    {
        $user = User::where('username', $username)->firstOrFail();
        return response()->json(['data' => new UserResource($user)]);
    }

    public function myBooks(Request $request): JsonResponse
    {
        $books = $request->user()
            ->books()
            ->with(['category'])
            ->latest()
            ->paginate(20);

        return response()->json(BookResource::collection($books));
    }

    public function myFavorites(Request $request): JsonResponse
    {
        $books = $request->user()
            ->favorites()
            ->with(['category', 'uploader'])
            ->paginate(20);

        return response()->json(BookResource::collection($books));
    }

    public function following(Request $request): JsonResponse
    {
        $following = $request->user()->following()->get();
        return response()->json(['data' => UserResource::collection($following)]);
    }

    public function userFollowers(string $username): JsonResponse
    {
        $user = User::where('username', $username)->firstOrFail();
        $followers = $user->followers()->get();
        return response()->json(['data' => UserResource::collection($followers)]);
    }

    public function userFollowing(string $username): JsonResponse
    {
        $user = User::where('username', $username)->firstOrFail();
        $following = $user->following()->get();
        return response()->json(['data' => UserResource::collection($following)]);
    }

    public function toggleFollow(Request $request, string $userId): JsonResponse
    {
        $target = User::findOrFail($userId);

        if ($target->id === $request->user()->id) {
            return response()->json(['message' => 'Cannot follow yourself.'], 422);
        }

        $exists = $request->user()->following()->where('following_id', $userId)->exists();

        if ($exists) {
            $request->user()->following()->detach($userId);
            $isFollowing = false;
        } else {
            $request->user()->following()->attach($userId, ['created_at' => now()]);
            $isFollowing = true;
        }

        return response()->json(['is_following' => $isFollowing]);
    }

    public function myReviews(Request $request): JsonResponse
    {
        $reviews = $request->user()
            ->reviews()
            ->with(['book:id,title,title_km,cover_url,author,file_type'])
            ->latest()
            ->paginate(20);

        return response()->json(\App\Http\Resources\ReviewResource::collection($reviews));
    }
}
