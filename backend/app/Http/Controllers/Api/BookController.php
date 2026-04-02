<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookResource;
use App\Http\Resources\ReviewResource;
use App\Models\Book;
use App\Models\Download;
use App\Models\Review;
use App\Services\BookService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\PersonalAccessToken;

class BookController extends Controller
{
    public function __construct(private readonly BookService $bookService)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Book::with(['category', 'uploader'])
            ->approved()
            ->where(function ($q) use ($user) {
                $q->where('is_private', false);
                if ($user) {
                    $q->orWhere('uploader_id', $user->id);
                }
            })
            ->when($request->category_id, fn($q) => $q->where('category_id', $request->category_id))
            ->when($request->language, fn($q) => $q->where('language', $request->language))
            ->when($request->search, fn($q) => $q->where(fn($s) => $s->where('title', 'ilike', '%' . $request->search . '%')->orWhere('author', 'ilike', '%' . $request->search . '%')))
            ->when($request->uploader_id, fn($q) => $q->where('uploader_id', $request->uploader_id))
            ->when(
                $request->is_favorited && $user,
                fn($q) => $q->whereHas('favoritedBy', fn($f) => $f->where('user_id', $user->id))
            )
            ->when(
                $request->my_uploads && $user,
                fn($q) => $q->where('uploader_id', $user->id)->withoutGlobalScopes()->where('status', 'approved')
            );

        $sort = $request->sort ?? 'newest';
        match ($sort) {
            'popular' => $query->orderByDesc('view_count'),
            'top_rated' => $query->orderByDesc('avg_rating'),
            'downloads' => $query->orderByDesc('download_count'),
            default => $query->orderByDesc('created_at'),
        };

        return response()->json(BookResource::collection($query->paginate(20)));
    }

    public function show(Request $request, string $id): JsonResponse
    {
        // Resolve user from Bearer token on this public route
        $user = $request->user();
        if (!$user && $request->bearerToken()) {
            $token = PersonalAccessToken::findToken($request->bearerToken());
            if ($token) {
                $user = $token->tokenable;
                $request->setUserResolver(fn() => $user);
            }
        }

        $book = Book::with(['category', 'uploader', 'tags'])->approved()->findOrFail($id);

        // Block private books from non-owners
        if ($book->is_private && (!$user || ($user->id !== $book->uploader_id && !$user->isAdmin()))) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $book->increment('view_count');

        return response()->json(['data' => new BookResource($book)]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'title_km' => 'nullable|string|max:255',
            'author' => 'required|string|max:200',
            'publisher' => 'nullable|string|max:255',
            'publication_year' => 'nullable|integer|min:1000|max:2100',
            'language' => 'required|in:km,en,fr,other',
            'category_id' => 'nullable|uuid|exists:categories,id',
            'description' => 'nullable|string|max:3000',
            'description_km' => 'nullable|string|max:3000',
            'cover_image' => 'nullable|image|max:5120',
            'book_file' => 'nullable|required_without:book_url|file|mimes:pdf,epub,mobi,docx|max:51200',
            'book_url' => 'nullable|required_without:book_file|url|max:2048',
        ]);

        $book = $this->bookService->storeBook(
            $request->user(),
            $validated,
            $request->file('book_file'),
            $request->file('cover_image')
        );

        return response()->json(['data' => new BookResource($book)], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $book = Book::findOrFail($id);

        if ($user->id !== $book->uploader_id && !$user->isAdmin()) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'title_km' => 'nullable|string|max:255',
            'author' => 'sometimes|string|max:200',
            'description' => 'nullable|string|max:3000',
            'description_km' => 'nullable|string|max:3000',
            'publication_year' => 'nullable|integer|min:1000|max:2100',
            'is_private' => 'sometimes|boolean',
        ]);

        $book->update($validated);

        return response()->json(['data' => new BookResource($book->fresh(['category', 'uploader']))]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $book = Book::findOrFail($id);

        if ($user->id !== $book->uploader_id && !$user->isAdmin()) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $book->delete();

        return response()->json(['message' => 'Book deleted.']);
    }

    public function featured(): JsonResponse
    {
        $books = Book::with(['category', 'uploader'])->featured()->approved()->latest()->take(10)->get();
        return response()->json(['data' => BookResource::collection($books)]);
    }

    public function newArrivals(): JsonResponse
    {
        $books = Book::with(['category', 'uploader'])->newArrivals()->approved()->take(20)->get();
        return response()->json(['data' => BookResource::collection($books)]);
    }

    public function search(Request $request): JsonResponse
    {
        $request->validate(['q' => 'required|string|min:2|max:100']);

        $books = Book::with(['category', 'uploader'])
            ->approved()
            ->where(fn($q) => $q->where('title', 'ilike', '%' . $request->q . '%')->orWhere('author', 'ilike', '%' . $request->q . '%'))
            ->paginate(20);

        return response()->json(BookResource::collection($books));
    }

    public function download(Request $request, string $id): JsonResponse
    {
        $book = Book::approved()->findOrFail($id);

        // For link-type books, return the external URL directly
        if ($book->file_type === 'link') {
            if ($request->user()) {
                Download::updateOrCreate(
                    ['user_id' => $request->user()->id, 'book_id' => $book->id],
                    ['downloaded_at' => now()]
                );
            }
            $book->increment('download_count');
            return response()->json(['url' => $book->file_url]);
        }

        if ($book->file_url && !Storage::disk('public')->exists($book->file_url)) {
            return response()->json(['message' => 'File not found.'], 404);
        }

        if ($request->user()) {
            Download::updateOrCreate(
                ['user_id' => $request->user()->id, 'book_id' => $book->id],
                ['downloaded_at' => now()]
            );
        }

        $book->increment('download_count');

        $url = $book->file_url ? Storage::disk('public')->url($book->file_url) : null;

        return response()->json(['url' => $url]);
    }

    public function toggleFavorite(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $book = Book::approved()->findOrFail($id);

        $exists = $user->favorites()->where('book_id', $book->id)->exists();

        if ($exists) {
            $user->favorites()->detach($book->id);
            $isFavorited = false;
        } else {
            $user->favorites()->attach($book->id, ['created_at' => now()]);
            $isFavorited = true;
        }

        return response()->json(['is_favorited' => $isFavorited]);
    }

    /**
     * Stream the PDF file directly through Laravel (avoids CORS issues with static files).
     */
    public function readFile(string $id): JsonResponse
    {
        $book = Book::approved()->findOrFail($id);

        // For link-type books, return the external URL for redirect
        if ($book->file_type === 'link') {
            return response()->json([
                'type' => 'external_link',
                'url' => $book->file_url,
            ]);
        }

        if (!$book->file_url || !Storage::disk('public')->exists($book->file_url)) {
            return response()->json(['message' => 'File not found.'], 404);
        }

        $path = $book->file_url;
        $mimeType = Storage::disk('public')->mimeType($path) ?: 'application/pdf';
        $contents = Storage::disk('public')->get($path);

        // Return as base64 JSON so browser download-manager extensions (e.g. IDM)
        // never see an application/pdf response and cannot trigger a download dialog.
        return response()->json([
            'type' => $mimeType,
            'data' => base64_encode($contents),
        ]);
    }

    // Reviews sub-resource
    public function reviews(string $id): JsonResponse
    {
        $book = Book::approved()->findOrFail($id);
        $reviews = $book->reviews()->with('user')->latest()->paginate(20);

        return response()->json(ReviewResource::collection($reviews));
    }

    public function storeReview(Request $request, string $id): JsonResponse
    {
        $book = Book::approved()->findOrFail($id);

        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'body' => 'nullable|string|max:1000',
        ]);

        $reviewBody = $request->input('body', $request->input('comment'));

        $review = Review::updateOrCreate(
            ['user_id' => $request->user()->id, 'book_id' => $book->id],
            ['rating' => $request->rating, 'body' => $reviewBody]
        );

        $book->recalculateRating();

        return response()->json(['data' => new ReviewResource($review->load('user'))], 201);
    }

    public function destroyReview(Request $request, string $bookId, string $reviewId): JsonResponse
    {
        $review = Review::where('id', $reviewId)->where('book_id', $bookId)->firstOrFail();

        if ($review->user_id !== $request->user()->id && !$request->user()->isAdmin()) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $review->delete();

        Book::find($bookId)?->recalculateRating();

        return response()->json(['message' => 'Review deleted.']);
    }
}
