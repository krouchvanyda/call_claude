<?php

namespace App\Features\Chat\Requests;

use App\Features\Chat\Models\ConversationType;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

/** Port of the Spring CreateConversationRequest. */
class CreateConversationRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'type' => ['required', Rule::in(ConversationType::values())],
            'memberIds' => ['required', 'array', 'min:1'],
            'memberIds.*' => ['integer'],
            'name' => ['nullable', 'string', 'max:255'],
            'avatarUrl' => ['nullable', 'string', 'max:1024'],
        ];
    }
}
