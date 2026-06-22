<?php

namespace App\Features\Employees\Controllers;

use App\Features\Employees\Dto\EmployeeDto;
use App\Features\Employees\Requests\CreateEmployeeRequest;
use App\Features\Employees\Requests\UpdateEmployeeRequest;
use App\Features\Employees\Services\EmployeeAvatarService;
use App\Features\Employees\Services\EmployeeService;
use App\Http\Controllers\Controller;
use App\Support\Pagination\PageQuery;
use App\Support\Pagination\PageResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EmployeeController extends Controller
{
    /** @var EmployeeService */
    private $employees;

    /** @var EmployeeAvatarService */
    private $avatars;

    public function __construct(EmployeeService $employees, EmployeeAvatarService $avatars)
    {
        $this->employees = $employees;
        $this->avatars = $avatars;
    }

    /** My own employee profile (used by the mobile My Profile screen). */
    public function me()
    {
        return EmployeeDto::from($this->employees->getByUserId((int) Auth::guard('api')->id()));
    }

    /** List employees, paginated; search across fullName / employeeNo / workEmail. */
    public function index(Request $request)
    {
        $page = $this->employees->list(PageQuery::fromRequest($request));
        return PageResponse::from($page, [EmployeeDto::class, 'from']);
    }

    /** Get one employee by id, with derived tenure and last-login. */
    public function show(int $id)
    {
        return EmployeeDto::from($this->employees->getById($id));
    }

    /** Create a new employee profile; userId is optional. */
    public function store(CreateEmployeeRequest $request)
    {
        return EmployeeDto::from($this->employees->create($request->validated()));
    }

    /** Partial update — only fields present in the body are touched. */
    public function update(UpdateEmployeeRequest $request, int $id)
    {
        $data = $request->validated();
        if (empty($data)) {
            return EmployeeDto::from($this->employees->getById($id));
        }
        return EmployeeDto::from($this->employees->update($id, $data));
    }

    /** Hard-delete an employee row (the linked user, if any, stays). */
    public function destroy(int $id)
    {
        $this->employees->delete($id);
        return null;
    }

    /** Upload my avatar (multipart `file`). */
    public function uploadMyAvatar(Request $request)
    {
        $userId = (int) Auth::guard('api')->id();
        return EmployeeDto::from($this->avatars->uploadForCurrentUser($userId, $request->file('file')));
    }

    /** Remove my avatar. */
    public function deleteMyAvatar()
    {
        $userId = (int) Auth::guard('api')->id();
        return EmployeeDto::from($this->avatars->deleteForCurrentUser($userId));
    }

    /** Admin: upload an avatar on behalf of any employee. */
    public function uploadAvatar(Request $request, int $id)
    {
        return EmployeeDto::from($this->avatars->uploadForEmployee($id, $request->file('file')));
    }

    /** Admin: remove an employee's avatar. */
    public function deleteAvatar(int $id)
    {
        return EmployeeDto::from($this->avatars->deleteForEmployee($id));
    }
}
