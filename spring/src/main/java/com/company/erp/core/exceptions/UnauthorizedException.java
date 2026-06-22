package com.company.erp.core.exceptions;

import com.company.erp.core.response.ErrorCodes;
import org.springframework.http.HttpStatus;

public class UnauthorizedException extends AppException {
    public UnauthorizedException(String message) {
        super(HttpStatus.UNAUTHORIZED, ErrorCodes.UNAUTHORIZED, message);
    }
}
