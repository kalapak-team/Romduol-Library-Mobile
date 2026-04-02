<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'rating' => $this->rating,
            'body' => $this->body,
            'comment' => $this->body,
            'user' => new UserResource($this->whenLoaded('user')),
            'book_id' => $this->book_id,
            'book' => $this->whenLoaded('book', fn() => [
                'id' => $this->book->id,
                'title' => $this->book->title,
                'title_km' => $this->book->title_km,
                'cover_url' => $this->book->cover_url,
                'author' => $this->book->author,
                'file_type' => $this->book->file_type,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
