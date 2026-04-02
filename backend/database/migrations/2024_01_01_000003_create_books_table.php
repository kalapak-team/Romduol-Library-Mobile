<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('books', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->string('title_km')->nullable();
            $table->string('author');
            $table->string('author_km')->nullable();
            $table->text('description')->nullable();
            $table->text('description_km')->nullable();
            $table->string('cover_url')->nullable();
            $table->string('file_url')->nullable();
            $table->string('file_type', 10)->default('pdf'); // pdf, epub, docx
            $table->bigInteger('file_size')->nullable();     // bytes
            $table->string('isbn', 20)->nullable();
            $table->string('publisher')->nullable();
            $table->smallInteger('publication_year')->nullable();
            $table->integer('pages')->nullable();
            $table->string('language', 5)->default('km');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->boolean('is_featured')->default(false);
            $table->integer('download_count')->default(0);
            $table->decimal('avg_rating', 3, 2)->default(0.00);
            $table->integer('review_count')->default(0);
            $table->foreignUuid('uploader_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'is_featured']);
            $table->index(['language', 'status']);
            $table->index('created_at');
            $table->fullText(['title', 'author', 'description']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('books');
    }
};
