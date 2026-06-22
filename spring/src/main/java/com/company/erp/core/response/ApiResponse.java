package com.company.erp.core.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.slf4j.MDC;

/**
 * Standard envelope returned by every endpoint:
 * {@code { success, message, data, errorCode, traceId }}.
 *
 * <p>Validation errors put per-field details inside {@code data.fieldErrors}
 * (a nested {@link ValidationErrorPayload}) per the README convention.</p>
 */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record ApiResponse<T>(
        boolean success,
        String message,
        T data,
        String errorCode,
        String traceId
) {
    public static <T> ApiResponse<T> ok(T data) {
        return ok(data, "Success");
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, message, data, null, currentTraceId());
    }

    public static ApiResponse<Void> empty(String message) {
        return new ApiResponse<>(true, message, null, null, currentTraceId());
    }

    public static <T> ApiResponse<T> error(String message, String errorCode) {
        return new ApiResponse<>(false, message, null, errorCode, currentTraceId());
    }

    public static <T> ApiResponse<T> error(String message, String errorCode, T data) {
        return new ApiResponse<>(false, message, data, errorCode, currentTraceId());
    }

    private static String currentTraceId() {
        return MDC.get("traceId");
    }
}
