package com.company.erp.core.exceptions;

import com.company.erp.core.response.ErrorCodes;
import org.springframework.http.HttpStatus;

public class BadRequestException extends AppException {
    public BadRequestException(String message) {
        super(HttpStatus.BAD_REQUEST, ErrorCodes.BAD_REQUEST, message);
    }
}
