<?php

namespace App\Features\Users\Controllers;

use App\Features\Users\Dto\PermissionDto;
use App\Features\Users\Dto\RoleDto;
use App\Features\Users\Requests\CreateRoleRequest;
use App\Features\Users\Requests\UpdateRoleRequest;
use App\Features\Users\Services\RoleService;
use App\Http\Controllers\Controller;

class RoleController extends Controller
{
    /** @var RoleService */
    private $roles;

    public function __construct(RoleService $roles)
    {
        $this->roles = $roles;
    }

    /** List all roles with their attached permission codes. */
    public function index()
    {
        return $this->roles->list()->map([RoleDto::class, 'from'])->values()->all();
    }

    /** List every permission code in the system — used by the role editor UI. */
    public function permissions()
    {
        return $this->roles->listPermissions()->map([PermissionDto::class, 'from'])->values()->all();
    }

    /** Get one role by id, including its permissions. */
    public function show(int $id)
    {
        return RoleDto::from($this->roles->getById($id));
    }

    /** Create a new role with a unique code and an initial permission set. */
    public function store(CreateRoleRequest $request)
    {
        $role = $this->roles->create([
            'code' => $request->input('code'),
            'name' => $request->input('name'),
            'description' => $request->input('description'),
            'permissions' => $request->permissionCodes(),
        ]);
        return RoleDto::from($role);
    }

    /** Update a role's name / description / permission set. */
    public function update(UpdateRoleRequest $request, int $id)
    {
        return RoleDto::from($this->roles->update($id, $request->validated()));
    }

    /** Delete a role (users referencing it lose those grants but stay). */
    public function destroy(int $id)
    {
        $this->roles->delete($id);
        return null;
    }
}
