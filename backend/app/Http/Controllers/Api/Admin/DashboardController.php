<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Book;
use App\Models\Setting;
use App\Models\User;
use App\Models\Download;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function stats(): JsonResponse
    {
        $totalUsers = User::count();
        $activeUsers = User::where('status', 'active')->count();
        $bannedUsers = User::where('status', 'banned')->count();
        $adminUsers = User::where('role', 'admin')->count();

        $totalBooks = Book::count();
        $approvedBooks = Book::where('status', 'approved')->count();
        $pendingBooks = Book::where('status', 'pending')->count();
        $rejectedBooks = Book::where('status', 'rejected')->count();
        $featuredBooks = Book::where('is_featured', true)->count();

        $totalDownloads = (int) Book::sum('download_count');

        // Recent users (last 5)
        $recentUsers = User::latest()->take(5)->get(['id', 'name', 'username', 'email', 'avatar_url', 'role', 'status', 'created_at']);

        // Recent pending books (last 5)
        $recentPendingBooks = Book::where('status', 'pending')
            ->with('uploader:id,name,username')
            ->latest()
            ->take(5)
            ->get(['id', 'title', 'title_km', 'cover_url', 'status', 'uploader_id', 'created_at']);

        return response()->json([
            'users' => [
                'total' => $totalUsers,
                'active' => $activeUsers,
                'banned' => $bannedUsers,
                'admins' => $adminUsers,
            ],
            'books' => [
                'total' => $totalBooks,
                'approved' => $approvedBooks,
                'pending' => $pendingBooks,
                'rejected' => $rejectedBooks,
                'featured' => $featuredBooks,
            ],
            'total_downloads' => $totalDownloads,
            'require_book_approval' => Setting::getBool('require_book_approval', true),
            'recent_users' => $recentUsers,
            'recent_pending_books' => $recentPendingBooks,
        ]);
    }
}
