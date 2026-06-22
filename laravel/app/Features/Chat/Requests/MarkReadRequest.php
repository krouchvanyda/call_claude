<?php

namespace App\Features\Chat\Requests;

use App\Support\Http\ApiFormRequest;

/** Port of the Spring MarkReadRequest (@NotNull lastReadMessageId). */
class MarkReadRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'lastReadMessageId' => ['required', 'integer'],
        ];
    }
}
