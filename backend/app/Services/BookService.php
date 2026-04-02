<?php

namespace App\Services;

use App\Models\Book;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\UploadedFile;

class BookService
{
    public function __construct(private readonly FileUploadService $uploader)
    {
    }

    public function storeBook(
        User $uploader,
        array $data,
        ?UploadedFile $bookFile = null,
        ?UploadedFile $coverImage = null
    ): Book {
        $coverPath = $coverImage ? $this->uploader->uploadCoverImage($coverImage) : null;

        $requireApproval = Setting::getBool('require_book_approval', true);

        // Determine file info based on upload type (file vs link)
        if ($bookFile) {
            $bookPath = $this->uploader->uploadBookFile($bookFile);
            $fileType = strtolower($bookFile->getClientOriginalExtension());
            $fileSize = (int) ceil($bookFile->getSize() / 1024);
        } else {
            $bookPath = $data['book_url'];
            $fileType = 'link';
            $fileSize = null;
        }

        return Book::create([
            'uploader_id' => $uploader->id,
            'title' => $data['title'],
            'title_km' => $data['title_km'] ?? null,
            'author' => $data['author'],
            'publisher' => $data['publisher'] ?? null,
            'publication_year' => $data['publication_year'] ?? null,
            'description' => $data['description'] ?? null,
            'description_km' => $data['description_km'] ?? null,
            'language' => $data['language'],
            'category_id' => $data['category_id'] ?? null,
            'file_url' => $bookPath,
            'file_type' => $fileType,
            'file_size' => $fileSize,
            'cover_url' => $coverPath ? asset('storage/' . $coverPath) : null,
            'status' => $requireApproval ? 'pending' : 'approved',
        ]);
    }

    public function deleteBookFiles(Book $book): void
    {
        if ($book->file_url) {
            $this->uploader->delete($book->file_url);
        }

        if ($book->cover_url) {
            // Extract relative path from URL
            $relative = str_replace(asset('storage/'), '', $book->cover_url);
            $this->uploader->delete($relative);
        }
    }
}
