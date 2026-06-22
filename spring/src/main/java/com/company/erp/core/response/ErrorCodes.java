package com.company.erp.core.response;

/** Stable machine-readable error codes returned in {@link ApiResponse#errorCode()}. */
public final class ErrorCodes {

    private ErrorCodes() {}

    public static final String VALIDATION_FAILED  = "VALIDATION_FAILED";
    public static final String UNAUTHORIZED       = "UNAUTHORIZED";
    public static final String FORBIDDEN          = "FORBIDDEN";
    public static final String NOT_FOUND          = "NOT_FOUND";
    public static final String CONFLICT           = "CONFLICT";
    public static final String BAD_REQUEST        = "BAD_REQUEST";
    public static final String RATE_LIMITED       = "RATE_LIMITED";
    public static final String UNSUPPORTED_MEDIA  = "UNSUPPORTED_MEDIA_TYPE";
    public static final String METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED";
    public static final String INTERNAL_ERROR     = "INTERNAL_ERROR";
}
