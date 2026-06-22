<?php

namespace App\Features\Users\Requests;

use App\Support\Http\ApiFormRequest;

class AssignRolesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'userIds' => ['required', 'array', 'min:1'],
            'userIds.*' => ['integer'],
            'roles' => ['present', 'array'],
            'roles.*' => ['string'],
            'mode' => ['nullable', 'string', 'in:ADD,REPLACE,REMOVE'],
        ];
    }

    /**
     * @return array<int, int>
     */
    public function userIds(): array
    {
        return array_values(array_unique(array_map('intval', $this->input('userIds', []))));
    }

    /**
     * @return array<int, string>
     */
    public function roleCodes(): array
    {
        return array_values(array_unique($this->input('roles', []) ?: []));
    }

    public function mode(): string
    {
        $mode = $this->input('mode');
        return $mode ?: 'ADD';
    }
}
