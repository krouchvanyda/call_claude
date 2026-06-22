<?php

namespace App\Support\Pagination;

use App\Support\Exceptions\BadRequestException;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

/**
 * Shared query convention for list endpoints:
 *   ?page=1&pageSize=20&search=…&sort=field:asc
 *
 * - page is 1-indexed
 * - pageSize is clamped to 1..MAX_PAGE_SIZE
 * - sort is field:asc|desc; callers pass an explicit whitelist of safe fields,
 *   keyed by API field name -> DB column.
 *
 * Port of the Spring PageQuery record.
 */
class PageQuery
{
    const MAX_PAGE_SIZE = 100;

    /** @var int */
    public $page;

    /** @var int */
    public $pageSize;

    /** @var string|null */
    public $search;

    /** @var string|null */
    public $sort;

    public function __construct(int $page, int $pageSize, ?string $search, ?string $sort)
    {
        if ($page <= 0) {
            $page = 1;
        }
        if ($pageSize <= 0) {
            $pageSize = 20;
        }
        if ($pageSize > self::MAX_PAGE_SIZE) {
            $pageSize = self::MAX_PAGE_SIZE;
        }
        $this->page = $page;
        $this->pageSize = $pageSize;
        $this->search = $search;
        $this->sort = $sort;
    }

    public static function fromRequest(Request $request): self
    {
        return new self(
            (int) $request->query('page', 1),
            (int) $request->query('pageSize', 20),
            $request->query('search'),
            $request->query('sort')
        );
    }

    /**
     * Apply the resolved sort to a query builder.
     *
     * @param array<string, string> $allowed  apiField => dbColumn
     * @param array{0:string,1:string} $default  [dbColumn, direction]
     */
    public function applySort(Builder $query, array $allowed, array $default): Builder
    {
        if ($this->sort === null || trim($this->sort) === '') {
            return $query->orderBy($default[0], $default[1]);
        }

        $parts = explode(':', $this->sort);
        $field = isset($parts[0]) ? trim($parts[0]) : '';
        $dir = isset($parts[1]) ? strtolower(trim($parts[1])) : 'asc';

        if (! array_key_exists($field, $allowed)) {
            throw new BadRequestException("Cannot sort by '".$field."'");
        }
        if ($dir !== 'asc' && $dir !== 'desc') {
            throw new BadRequestException("Sort direction must be 'asc' or 'desc'");
        }

        return $query->orderBy($allowed[$field], $dir);
    }
}
