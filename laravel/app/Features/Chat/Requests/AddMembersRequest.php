<?php

namespace App\Features\Chat\Requests;

use App\Support\Http\ApiFormRequest;

/** Port of the Spring AddMembersRequest (@NotEmpty memberIds). */
class AddMembersRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'memberIds' => ['required', 'array', 'min:1'],
            'memberIds.*' => ['integer'],
        ];
    }
}
