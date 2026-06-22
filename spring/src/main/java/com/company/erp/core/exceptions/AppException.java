package com.company.erp.core.exceptions;

import org.springframework.http.HttpStatus;

/**
 * Base class for application-level exceptions with a known HTTP status + stable
 * error code. Throw subclasses freely from services and controllers; the global
 * handler translates them into the standard envelope.
 */
public class AppException extends RuntimeException {

    private final HttpStatus status;
    private final String errorCode;

    public AppException(HttpStatus status, String errorCode, String message) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
    }

    public HttpStatus status() {
        return status;
    }

    public String errorCode() {
        return errorCode;
    }
}
