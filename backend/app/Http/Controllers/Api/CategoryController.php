<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::withCount('books')
            ->whereNull('parent_id')
            ->with([
                'children' => fn($q) => $q->withCount('books'),
            ])
            ->orderBy('sort_order')
            ->get();

        return response()->json(['data' => CategoryResource::collection($categories)]);
    }

    public function show(string $id): JsonResponse
    {
        $category = Category::withCount('books')->findOrFail($id);
        return response()->json(['data' => new CategoryResource($category)]);
    }
}
