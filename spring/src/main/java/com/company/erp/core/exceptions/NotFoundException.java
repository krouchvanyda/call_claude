package com.company.erp.core.exceptions;

import com.company.erp.core.response.ErrorCodes;
import org.springframework.http.HttpStatus;

public class NotFoundException extends AppException {
    public NotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, ErrorCodes.NOT_FOUND, message);
    }
}
