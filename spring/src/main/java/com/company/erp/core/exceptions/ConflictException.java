package com.company.erp.core.exceptions;

import com.company.erp.core.response.ErrorCodes;
import org.springframework.http.HttpStatus;

public class ConflictException extends AppException {
    public ConflictException(String message) {
        super(HttpStatus.CONFLICT, ErrorCodes.CONFLICT, message);
    }
}
