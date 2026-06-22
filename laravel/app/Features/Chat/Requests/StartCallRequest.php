<?php

namespace App\Features\Chat\Requests;

use App\Features\Chat\Models\CallType;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

/** Port of the Spring StartCallRequest (@NotNull type). */
class StartCallRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'type' => ['required', Rule::in(CallType::values())],
        ];
    }
}
