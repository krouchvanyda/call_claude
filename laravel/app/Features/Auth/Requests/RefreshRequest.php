<?php

namespace App\Features\Auth\Requests;

use App\Support\Http\ApiFormRequest;

class RefreshRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'refreshToken' => ['required', 'string'],
        ];
    }
}
