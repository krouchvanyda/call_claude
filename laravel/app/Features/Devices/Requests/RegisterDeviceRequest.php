<?php

namespace App\Features\Devices\Requests;

use App\Features\Devices\Models\DevicePlatform;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

class RegisterDeviceRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'deviceId' => ['required', 'string', 'max:128'],
            'fcmToken' => ['required', 'string'],
            'platform' => ['required', Rule::in(DevicePlatform::values())],
            'appVersion' => ['nullable', 'string', 'max:32'],
        ];
    }
}
