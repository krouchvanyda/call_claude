<?php

namespace App\Features\Chat\Requests;

use App\Features\Chat\Models\MessageType;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

/**
 * Port of the Spring SendMessageRequest. Type-specific body/attachment rules
 * are enforced in MessageService::validateBody (matching the Java service),
 * so only the field-shape constraints live here.
 */
class SendMessageRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'type' => ['required', Rule::in(MessageType::values())],
            'body' => ['nullable', 'string'],
            'attachmentUrl' => ['nullable', 'string', 'max:1024'],
            'attachmentContentType' => ['nullable', 'string', 'max:64'],
            'attachmentSizeBytes' => ['nullable', 'integer'],
            'durationSeconds' => ['nullable', 'integer'],
            'replyToMessageId' => ['nullable', 'integer'],
        ];
    }
}
