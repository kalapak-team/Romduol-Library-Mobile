<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'name_km' => $this->name_km,
            'username' => $this->username,
            'email' => $this->whenNotNull($this->when(
                $request->user()?->id === $this->id || $request->user()?->isAdmin(),
                $this->email
            )),
            'avatar_url' => $this->avatar_url,
            'bio' => $this->bio,
            'bio_km' => $this->bio_km,
            'role' => $this->role,
            'status' => $this->status,
            'book_count' => $this->book_count,
            'books_uploaded' => $this->books()->count(),
            'books_downloaded' => $this->downloads()->count(),
            'followers_count' => $this->followers()->count(),
            'following_count' => $this->following()->count(),
            'is_following' => $request->user()
                ? $this->followers()->where('follower_id', $request->user()->id)->exists()
                : false,
            'language' => $this->language,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
