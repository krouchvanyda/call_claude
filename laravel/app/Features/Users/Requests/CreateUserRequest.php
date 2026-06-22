<?php

namespace App\Features\Users\Requests;

use App\Support\Http\ApiFormRequest;

class CreateUserRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'max:255'],
            'password' => ['required', 'string', 'min:8', 'max:100'],
            'fullName' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'roles' => ['nullable', 'array'],
            'roles.*' => ['string'],
        ];
    }

    /**
     * @return array<int, string>
     */
    public function roleCodes(): array
    {
        return array_values(array_unique($this->input('roles', []) ?: []));
    }
}
