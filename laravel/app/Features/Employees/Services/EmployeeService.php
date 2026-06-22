<?php

namespace App\Features\Employees\Services;

use App\Features\Employees\Models\Employee;
use App\Features\Employees\Models\EmployeeStatus;
use App\Support\Exceptions\ConflictException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Pagination\PageQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;

class EmployeeService
{
    /** @var array<string, string> apiField => dbColumn */
    private const ALLOWED_SORT = [
        'employeeNo' => 'employee_no',
        'fullName' => 'full_name',
        'department' => 'department',
        'hireDate' => 'hire_date',
        'status' => 'status',
        'createdAt' => 'created_at',
    ];

    /** apiField => column for camelCase request payloads. */
    private const FIELD_MAP = [
        'userId' => 'user_id',
        'employeeNo' => 'employee_no',
        'fullName' => 'full_name',
        'workEmail' => 'work_email',
        'phone' => 'phone',
        'position' => 'position',
        'department' => 'department',
        'hireDate' => 'hire_date',
        'dateOfBirth' => 'date_of_birth',
        'gender' => 'gender',
        'address' => 'address',
        'avatarUrl' => 'avatar_url',
        'emergencyContact' => 'emergency_contact',
        'emergencyPhone' => 'emergency_phone',
        'status' => 'status',
    ];

    public function list(PageQuery $query): LengthAwarePaginator
    {
        $builder = Employee::query();

        $q = $query->search;
        if ($q !== null && $q !== '') {
            $like = '%'.strtolower($q).'%';
            $builder->where(function ($w) use ($like) {
                $w->whereRaw('LOWER(full_name) LIKE ?', [$like])
                    ->orWhereRaw('LOWER(employee_no) LIKE ?', [$like])
                    ->orWhereRaw("LOWER(COALESCE(work_email, '')) LIKE ?", [$like]);
            });
        }

        $query->applySort($builder, self::ALLOWED_SORT, ['full_name', 'asc']);

        return $builder->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function getById(int $id): Employee
    {
        $e = Employee::query()->find($id);
        if (! $e) {
            throw new NotFoundException('Employee not found');
        }
        return $e;
    }

    public function getByUserId(int $userId): Employee
    {
        $e = Employee::query()->where('user_id', $userId)->first();
        if (! $e) {
            throw new NotFoundException('Employee profile not found for current user');
        }
        return $e;
    }

    /**
     * @param array<string, mixed> $data
     */
    public function create(array $data): Employee
    {
        if (Employee::query()->where('employee_no', $data['employeeNo'])->exists()) {
            throw new ConflictException('Employee number already in use');
        }
        $userId = $data['userId'] ?? null;
        if ($userId !== null && Employee::query()->where('user_id', $userId)->exists()) {
            throw new ConflictException('This user is already linked to another employee profile');
        }

        $e = new Employee();
        foreach (self::FIELD_MAP as $apiField => $column) {
            if (array_key_exists($apiField, $data)) {
                $e->{$column} = $data[$apiField];
            }
        }
        $e->status = $data['status'] ?? EmployeeStatus::ACTIVE;
        $e->save();

        return $e;
    }

    /**
     * @param array<string, mixed> $data  partial
     */
    public function update(int $id, array $data): Employee
    {
        $e = $this->getById($id);

        if (array_key_exists('employeeNo', $data) && $data['employeeNo'] !== null
            && $data['employeeNo'] !== $e->employee_no) {
            if (Employee::query()->where('employee_no', $data['employeeNo'])->exists()) {
                throw new ConflictException('Employee number already in use');
            }
            $e->employee_no = $data['employeeNo'];
        }
        if (array_key_exists('userId', $data) && $data['userId'] !== null
            && (int) $data['userId'] !== (int) $e->user_id) {
            if (Employee::query()->where('user_id', $data['userId'])->exists()) {
                throw new ConflictException('This user is already linked to another employee profile');
            }
            $e->user_id = $data['userId'];
        }

        $simple = [
            'fullName', 'workEmail', 'phone', 'position', 'department', 'hireDate',
            'dateOfBirth', 'gender', 'address', 'avatarUrl', 'emergencyContact',
            'emergencyPhone', 'status',
        ];
        foreach ($simple as $apiField) {
            if (array_key_exists($apiField, $data) && $data[$apiField] !== null) {
                $e->{self::FIELD_MAP[$apiField]} = $data[$apiField];
            }
        }
        $e->save();

        return $e;
    }

    public function delete(int $id): void
    {
        $this->getById($id)->delete();
    }

    /**
     * Updates last_login_at for the employee linked to the given user, if any.
     * Silent when no employee is linked.
     */
    public function touchLastLoginByUserId(int $userId): void
    {
        $e = Employee::query()->where('user_id', $userId)->first();
        if ($e) {
            $e->last_login_at = Carbon::now();
            $e->save();
        }
    }
}
