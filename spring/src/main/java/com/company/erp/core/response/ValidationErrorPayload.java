package com.company.erp.core.response;

import java.util.List;

/** Validation-error payload nested under {@code data.fieldErrors}. */
public record ValidationErrorPayload(List<FieldError> fieldErrors) {
}
