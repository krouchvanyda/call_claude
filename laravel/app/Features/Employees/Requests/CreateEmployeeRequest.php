<?php

namespace App\Features\Employees\Requests;

use App\Features\Employees\Models\EmployeeStatus;
use App\Support\Http\ApiFormRequest;
use Illuminate\Validation\Rule;

class CreateEmployeeRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'userId' => ['nullable', 'integer'],
            'employeeNo' => ['required', 'string', 'max:64'],
            'fullName' => ['required', 'string', 'max:255'],
            'workEmail' => ['nullable', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'position' => ['nullable', 'string', 'max:128'],
            'department' => ['nullable', 'string', 'max:128'],
            'hireDate' => ['nullable', 'date'],
            'dateOfBirth' => ['nullable', 'date'],
            'gender' => ['nullable', 'string', 'max:16'],
            'address' => ['nullable', 'string', 'max:1024'],
            'avatarUrl' => ['nullable', 'string', 'max:1024'],
            'emergencyContact' => ['nullable', 'string', 'max:255'],
            'emergencyPhone' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(EmployeeStatus::values())],
        ];
    }
}
