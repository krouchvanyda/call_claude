<?php

namespace App\Features\Chat\Requests;

use App\Support\Http\ApiFormRequest;

/** Port of the Spring UpdateConversationRequest. */
class UpdateConversationRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['nullable', 'string', 'max:255'],
            'avatarUrl' => ['nullable', 'string', 'max:1024'],
        ];
    }
}
