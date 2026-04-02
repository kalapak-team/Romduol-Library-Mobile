<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\Admin\BookController as AdminBookController;
use App\Http\Controllers\Api\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\Admin\SettingsController as AdminSettingsController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Models\Setting;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Romduol Library v1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ── Auth ──────────────────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
            Route::post('profile', [AuthController::class, 'updateProfile']);
            Route::post('change-password', [AuthController::class, 'changePassword']);
        });
    });

    // ── Categories ────────────────────────────────────────────────────────
    Route::get('categories', [CategoryController::class, 'index']);
    Route::get('categories/{id}', [CategoryController::class, 'show']);

    // ── Books (public, with optional auth for favorite status) ──────────
    Route::get('books', [BookController::class, 'index']);
    Route::get('books/featured', [BookController::class, 'featured']);
    Route::get('books/new-arrivals', [BookController::class, 'newArrivals']);
    Route::get('books/search', [BookController::class, 'search']);
    Route::get('books/{id}', [BookController::class, 'show']);
    Route::get('books/{id}/read', [BookController::class, 'readFile']);
    Route::get('books/{id}/reviews', [BookController::class, 'reviews']);

    // ── Books (auth required) ─────────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('books', [BookController::class, 'store']);
        Route::patch('books/{id}', [BookController::class, 'update']);
        Route::delete('books/{id}', [BookController::class, 'destroy']);
        Route::get('books/{id}/download', [BookController::class, 'download']);
        Route::post('books/{id}/favorite', [BookController::class, 'toggleFavorite']);
        Route::post('books/{id}/reviews', [BookController::class, 'storeReview']);
        Route::delete('books/{bookId}/reviews/{reviewId}', [BookController::class, 'destroyReview']);

        // ── Current User ─────────────────────────────────────────────────
        Route::get('me/books', [UserController::class, 'myBooks']);
        Route::get('me/favorites', [UserController::class, 'myFavorites']);
        Route::get('me/reviews', [UserController::class, 'myReviews']);
        Route::get('me/following', [UserController::class, 'following']);
        Route::post('users/{id}/follow', [UserController::class, 'toggleFollow']);
    });

    // ── User Profiles ─────────────────────────────────────────────────────
    Route::get('users/{username}/followers', [UserController::class, 'userFollowers']);
    Route::get('users/{username}/following', [UserController::class, 'userFollowing']);
    Route::get('users/{username}', [UserController::class, 'show']);

    // ── Public Settings ─────────────────────────────────────────────────
    Route::get('settings/public', function () {
        return response()->json([
            'require_book_approval' => Setting::getBool('require_book_approval', true),
        ]);
    });

    // ── Admin ─────────────────────────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
        Route::get('dashboard', [AdminDashboardController::class, 'stats']);

        Route::get('books', [AdminBookController::class, 'index']);
        Route::post('books/{id}/approve', [AdminBookController::class, 'approve']);
        Route::post('books/{id}/reject', [AdminBookController::class, 'reject']);
        Route::post('books/{id}/feature', [AdminBookController::class, 'feature']);
        Route::put('books/{id}', [AdminBookController::class, 'update']);
        Route::delete('books/{id}', [AdminBookController::class, 'destroy']);

        Route::get('users', [AdminUserController::class, 'index']);
        Route::post('users/{id}/ban', [AdminUserController::class, 'ban']);
        Route::post('users/{id}/unban', [AdminUserController::class, 'unban']);
        Route::post('users/{id}/promote', [AdminUserController::class, 'promote']);
        Route::delete('users/{id}', [AdminUserController::class, 'destroy']);

        Route::get('settings', [AdminSettingsController::class, 'index']);
        Route::put('settings', [AdminSettingsController::class, 'update']);
    });
});
