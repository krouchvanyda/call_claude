<?php

namespace App\Features\Employees\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * HR-side employee profile. May link to a login user (user_id, unique).
 *
 * @property int $id
 * @property int|null $user_id
 * @property string $employee_no
 * @property string $full_name
 * @property string|null $work_email
 * @property string|null $phone
 * @property string|null $position
 * @property string|null $department
 * @property \Illuminate\Support\Carbon|null $hire_date
 * @property \Illuminate\Support\Carbon|null $date_of_birth
 * @property string|null $gender
 * @property string|null $address
 * @property string|null $avatar_url
 * @property string|null $avatar_content_type
 * @property \Illuminate\Support\Carbon|null $avatar_uploaded_at
 * @property string|null $emergency_contact
 * @property string|null $emergency_phone
 * @property \Illuminate\Support\Carbon|null $last_login_at
 * @property string $status
 */
class Employee extends Model
{
    use BlamesUser;

    protected $table = 'employees';

    protected $fillable = [
        'user_id', 'employee_no', 'full_name', 'work_email', 'phone', 'position',
        'department', 'hire_date', 'date_of_birth', 'gender', 'address', 'avatar_url',
        'avatar_content_type', 'avatar_uploaded_at', 'emergency_contact', 'emergency_phone',
        'last_login_at', 'status',
    ];

    protected $casts = [
        'hire_date' => 'date',
        'date_of_birth' => 'date',
        'avatar_uploaded_at' => 'datetime',
        'last_login_at' => 'datetime',
    ];

    protected $attributes = [
        'status' => EmployeeStatus::ACTIVE,
    ];
}
