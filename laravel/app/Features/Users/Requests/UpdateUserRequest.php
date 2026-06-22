<?php

namespace App\Features\Users\Requests;

use App\Support\Http\ApiFormRequest;

class UpdateUserRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'fullName' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:50'],
            'avatarUrl' => ['sometimes', 'nullable', 'string', 'max:1024'],
            'enabled' => ['sometimes', 'nullable', 'boolean'],
            'roles' => ['sometimes', 'nullable', 'array'],
            'roles.*' => ['string'],
        ];
    }
}
