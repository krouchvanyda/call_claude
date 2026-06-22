<?php

namespace App\Features\Chat\Requests;

use App\Support\Http\ApiFormRequest;

/** Port of the Spring ToggleReactionRequest (@NotBlank @Size(max=16) emoji). */
class ToggleReactionRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'emoji' => ['required', 'string', 'max:16'],
        ];
    }
}
