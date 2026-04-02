<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookResource;
use App\Models\Book;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookController extends Controller
{
    public function index(Request $request)
    {
        $query = Book::with(['uploader', 'category']);

        if ($request->status) {
            $query->where('status', $request->status);
        }

        if ($request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                    ->orWhere('title_km', 'ilike', "%{$search}%")
                    ->orWhere('author', 'ilike', "%{$search}%");
            });
        }

        if ($request->featured) {
            $query->where('is_featured', true);
        }

        $books = $query->latest()->paginate(20);

        return BookResource::collection($books);
    }

    public function approve(string $id): JsonResponse
    {
        $book = Book::findOrFail($id);
        $book->update(['status' => 'approved']);
        return response()->json(['message' => 'Book approved.', 'data' => new BookResource($book)]);
    }

    public function reject(Request $request, string $id): JsonResponse
    {
        $request->validate(['reason' => 'nullable|string|max:500']);

        $book = Book::findOrFail($id);
        $book->update(['status' => 'rejected']);

        return response()->json(['message' => 'Book rejected.']);
    }

    public function feature(string $id): JsonResponse
    {
        $book = Book::approved()->findOrFail($id);
        $book->update(['is_featured' => !$book->is_featured]);

        return response()->json([
            'message' => $book->is_featured ? 'Book featured.' : 'Book unfeatured.',
            'is_featured' => $book->is_featured,
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $book = Book::findOrFail($id);

        if ((string) $book->uploader_id !== (string) $user->id) {
            return response()->json(['message' => 'Forbidden. You can only edit your own books.'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'title_km' => 'nullable|string|max:255',
            'author' => 'sometimes|string|max:200',
            'description' => 'nullable|string|max:3000',
            'description_km' => 'nullable|string|max:3000',
            'publication_year' => 'nullable|integer|min:1000|max:2100',
            'is_private' => 'sometimes|boolean',
            'is_featured' => 'sometimes|boolean',
            'status' => 'sometimes|in:pending,approved,rejected',
        ]);

        $book->update($validated);

        return response()->json(['data' => new BookResource($book->fresh(['category', 'uploader']))]);
    }

    public function destroy(string $id): JsonResponse
    {
        $book = Book::findOrFail($id);
        $book->delete();

        return response()->json(['message' => 'Book deleted.']);
    }
}
