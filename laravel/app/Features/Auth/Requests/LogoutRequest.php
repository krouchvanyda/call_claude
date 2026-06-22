<?php

namespace App\Features\Auth\Requests;

use App\Support\Http\ApiFormRequest;

class LogoutRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'refreshToken' => ['required', 'string'],
        ];
    }
}
