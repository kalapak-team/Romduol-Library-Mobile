<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();

        return [
            'id' => $this->id,
            'user_id' => $this->uploader_id,
            'category_id' => $this->category_id,
            'title' => $this->title,
            'title_km' => $this->title_km,
            'author' => $this->author,
            'author_km' => $this->author_km,
            'description' => $this->description,
            'description_km' => $this->description_km,
            'language' => $this->language,
            'cover_url' => $this->cover_url,
            'file_url' => $this->file_type === 'link'
                ? $this->file_url
                : ($this->file_url
                    ? url('/api/v1/books/' . $this->id . '/read')
                    : null),
            'file_type' => $this->file_type,
            'file_size_kb' => $this->file_size,
            'isbn' => $this->isbn,
            'publisher' => $this->publisher,
            'publish_year' => $this->publication_year,
            'pages' => $this->pages,
            'avg_rating' => round((float) $this->avg_rating, 2),
            'review_count' => $this->review_count,
            'view_count' => $this->view_count,
            'download_count' => $this->download_count,
            'is_featured' => (bool) $this->is_featured,
            'is_private' => (bool) $this->is_private,
            'status' => $this->status,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'uploader' => new UserResource($this->whenLoaded('uploader')),
            'tags' => $this->whenLoaded('tags', fn() => $this->tags->pluck('name')),
            'is_favorited' => $user
                ? ($this->relationLoaded('favoritedBy')
                    ? $this->favoritedBy->contains('id', $user->id)
                    : $this->favoritedBy()->where('user_id', $user->id)->exists())
                : false,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
