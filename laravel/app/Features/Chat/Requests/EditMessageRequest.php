<?php

namespace App\Features\Chat\Requests;

use App\Support\Http\ApiFormRequest;

/** Port of the Spring EditMessageRequest (@NotBlank body). */
class EditMessageRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'body' => ['required', 'string'],
        ];
    }
}
