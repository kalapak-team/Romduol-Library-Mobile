<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Model;

class Book extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'title',
        'title_km',
        'author',
        'author_km',
        'description',
        'description_km',
        'cover_url',
        'file_url',
        'file_type',
        'file_size',
        'isbn',
        'publisher',
        'publication_year',
        'pages',
        'language',
        'status',
        'is_featured',
        'is_private',
        'download_count',
        'avg_rating',
        'review_count',
        'uploader_id',
        'category_id',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'is_private' => 'boolean',
        'avg_rating' => 'float',
        'publication_year' => 'integer',
        'pages' => 'integer',
        'download_count' => 'integer',
        'review_count' => 'integer',
        'file_size' => 'integer',
    ];

    // ─── Relationships ───────────────────────────────────────────────────

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploader_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class, 'book_tag');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function downloads(): HasMany
    {
        return $this->hasMany(Download::class);
    }

    public function favoritedBy(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites')
            ->withPivot('created_at');
    }

    // ─── Scopes ────────────────────────────────────────────────────────

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true)->approved();
    }

    public function scopeNewArrivals($query, int $days = 30)
    {
        return $query->approved()
            ->where('created_at', '>=', now()->subDays($days))
            ->orderByDesc('created_at');
    }

    // ─── Helpers ─────────────────────────────────────────────────────────

    public function incrementDownloadCount(): void
    {
        $this->increment('download_count');
    }

    public function recalculateRating(): void
    {
        $stats = $this->reviews()
            ->selectRaw('AVG(rating) as avg, COUNT(*) as cnt')
            ->first();

        $this->update([
            'avg_rating' => round($stats->avg ?? 0, 2),
            'review_count' => $stats->cnt ?? 0,
        ]);
    }
}
