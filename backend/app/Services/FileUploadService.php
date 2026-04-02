<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class FileUploadService
{
    private string $disk;

    public function __construct()
    {
        $this->disk = config('filesystems.default', 'public');
    }

    public function uploadBookFile(UploadedFile $file): string
    {
        $name = Str::uuid() . '.' . $file->getClientOriginalExtension();
        return $file->storeAs('books', $name, $this->disk);
    }

    public function uploadCoverImage(UploadedFile $file): string
    {
        $name = Str::uuid() . '.' . $file->getClientOriginalExtension();
        return $file->storeAs('covers', $name, $this->disk);
    }

    public function uploadAvatar(UploadedFile $file): string
    {
        $name = Str::uuid() . '.' . $file->getClientOriginalExtension();
        return $file->storeAs('avatars', $name, $this->disk);
    }

    public function delete(?string $path): void
    {
        if ($path && Storage::disk($this->disk)->exists($path)) {
            Storage::disk($this->disk)->delete($path);
        }
    }

    public function temporaryUrl(string $path, int $minutes = 10): string
    {
        // S3 supports temporaryUrl; fall back to public URL for local disk.
        if ($this->disk === 's3') {
            return Storage::disk($this->disk)->temporaryUrl($path, now()->addMinutes($minutes));
        }

        return Storage::disk($this->disk)->url($path);
    }
}
