<?php

namespace App\Features\Users\Requests;

use App\Support\Http\ApiFormRequest;

class CreateRoleRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'code' => ['required', 'string', 'max:64'],
            'name' => ['required', 'string', 'max:128'],
            'description' => ['nullable', 'string', 'max:255'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string'],
        ];
    }

    /**
     * @return array<int, string>
     */
    public function permissionCodes(): array
    {
        return array_values(array_unique($this->input('permissions', []) ?: []));
    }
}
