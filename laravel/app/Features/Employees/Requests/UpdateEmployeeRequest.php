<?php

namespace App\Features\Employees\Requests;

use App\Features\Employees\Models\EmployeeStatus;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateEmployeeRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'userId' => ['sometimes', 'nullable', 'integer'],
            'employeeNo' => ['sometimes', 'nullable', 'string', 'max:64'],
            'fullName' => ['sometimes', 'nullable', 'string', 'max:255'],
            'workEmail' => ['sometimes', 'nullable', 'email', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:50'],
            'position' => ['sometimes', 'nullable', 'string', 'max:128'],
            'department' => ['sometimes', 'nullable', 'string', 'max:128'],
            'hireDate' => ['sometimes', 'nullable', 'date'],
            'dateOfBirth' => ['sometimes', 'nullable', 'date'],
            'gender' => ['sometimes', 'nullable', 'string', 'max:16'],
            'address' => ['sometimes', 'nullable', 'string', 'max:1024'],
            'avatarUrl' => ['sometimes', 'nullable', 'string', 'max:1024'],
            'emergencyContact' => ['sometimes', 'nullable', 'string', 'max:255'],
            'emergencyPhone' => ['sometimes', 'nullable', 'string', 'max:50'],
            'status' => ['sometimes', 'nullable', Rule::in(EmployeeStatus::values())],
        ];
    }
}
