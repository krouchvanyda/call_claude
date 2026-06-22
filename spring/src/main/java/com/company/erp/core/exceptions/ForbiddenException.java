package com.company.erp.core.exceptions;

import com.company.erp.core.response.ErrorCodes;
import org.springframework.http.HttpStatus;

public class ForbiddenException extends AppException {
    public ForbiddenException(String message) {
        super(HttpStatus.FORBIDDEN, ErrorCodes.FORBIDDEN, message);
    }
}
