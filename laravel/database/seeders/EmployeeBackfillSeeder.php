<?php

namespace Database\Seeders;

use App\Features\Employees\Models\Employee;
use App\Features\Employees\Models\EmployeeStatus;
use App\Features\Users\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Log;

/**
 * Creates an Employee row for any User that doesn't already have one. Port of
 * EmployeeBackfillBootstrap. Employee numbers are deterministic:
 * EMP-<userId padded to 5>. Idempotent.
 */
class EmployeeBackfillSeeder extends Seeder
{
    public function run(): void
    {
        $created = 0;

        User::query()->orderBy('id')->each(function (User $u) use (&$created) {
            if (Employee::query()->where('user_id', $u->id)->exists()) {
                return;
            }
            $employeeNo = 'EMP-'.str_pad((string) $u->id, 5, '0', STR_PAD_LEFT);
            if (Employee::query()->where('employee_no', $employeeNo)->exists()) {
                Log::warning("Skipping backfill for user {$u->id}: employee_no {$employeeNo} already taken");
                return;
            }

            $e = new Employee();
            $e->user_id = $u->id;
            $e->employee_no = $employeeNo;
            $e->full_name = $u->full_name;
            $e->work_email = $u->email;
            $e->phone = $u->phone;
            $e->status = EmployeeStatus::ACTIVE;
            $e->save();
            $created++;
        });

        if ($created > 0) {
            Log::info("Employee backfill: created {$created} employee row(s) for existing users");
        }
    }
}
