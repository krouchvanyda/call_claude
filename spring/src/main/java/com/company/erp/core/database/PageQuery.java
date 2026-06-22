package com.company.erp.core.database;

import com.company.erp.core.exceptions.BadRequestException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.util.Set;

/**
 * Shared query convention for list endpoints:
 * {@code ?page=1&pageSize=20&search=…&sort=field:asc}.
 *
 * <ul>
 *   <li>{@code page} is 1-indexed (translated to Spring's 0-based internally).</li>
 *   <li>{@code pageSize} is clamped to {@code 1..MAX_PAGE_SIZE}.</li>
 *   <li>{@code sort} is {@code field:asc|desc}; controllers pass an explicit
 *       whitelist of safe fields.</li>
 * </ul>
 */
public record PageQuery(int page, int pageSize, String search, String sort) {

    public static final int MAX_PAGE_SIZE = 100;

    public PageQuery {
        if (page <= 0) page = 1;
        if (pageSize <= 0) pageSize = 20;
        if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
    }

    public Pageable toPageable(Set<String> allowedSortFields, Sort defaultSort) {
        Sort resolved = (sort == null || sort.isBlank())
                ? defaultSort
                : parseSort(sort, allowedSortFields);
        return PageRequest.of(page - 1, pageSize, resolved);
    }

    private static Sort parseSort(String raw, Set<String> allowed) {
        String[] parts = raw.split(":");
        String field = parts.length > 0 ? parts[0].trim() : "";
        String dir   = parts.length > 1 ? parts[1].trim().toLowerCase() : "asc";
        if (!allowed.contains(field)) {
            throw new BadRequestException("Cannot sort by '" + field + "'");
        }
        Sort.Direction direction = switch (dir) {
            case "asc"  -> Sort.Direction.ASC;
            case "desc" -> Sort.Direction.DESC;
            default -> throw new BadRequestException("Sort direction must be 'asc' or 'desc'");
        };
        return Sort.by(direction, field);
    }
}
