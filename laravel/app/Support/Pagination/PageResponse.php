<?php

namespace App\Support\Pagination;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * Page wrapper hiding the paginator internals; clients see 1-indexed page
 * numbers per the shared pagination convention. Port of the Spring
 * PageResponse record.
 */
final class PageResponse
{
    /**
     * @param LengthAwarePaginator $paginator
     * @param callable|null $transform  maps each item to its DTO/array form
     * @return array<string, mixed>
     */
    public static function from(LengthAwarePaginator $paginator, ?callable $transform = null): array
    {
        $items = $paginator->items();
        if ($transform !== null) {
            $items = array_map($transform, $items);
        }

        return [
            'items' => array_values($items),
            'page' => $paginator->currentPage(),
            'pageSize' => $paginator->perPage(),
            'totalItems' => $paginator->total(),
            'totalPages' => $paginator->lastPage(),
        ];
    }
}
