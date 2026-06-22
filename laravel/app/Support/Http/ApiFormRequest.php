<?php

namespace App\Support\Http;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\ValidationException;

/**
 * Base request for the API. Always throws ValidationException on failure (no
 * web-style redirect), so the exception handler renders the standard
 * VALIDATION_FAILED envelope with per-field details.
 */
abstract class ApiFormRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function failedValidation(Validator $validator)
    {
        throw new ValidationException($validator);
    }
}
