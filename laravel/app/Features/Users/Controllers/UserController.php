<?php

namespace App\Features\Users\Controllers;

use App\Features\Users\Dto\UserDto;
use App\Features\Users\Requests\AssignRolesRequest;
use App\Features\Users\Requests\CreateUserRequest;
use App\Features\Users\Requests\UpdateUserRequest;
use App\Features\Users\Services\UserService;
use App\Http\Controllers\Controller;
use App\Support\Pagination\PageQuery;
use App\Support\Pagination\PageResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    /** @var UserService */
    private $users;

    public function __construct(UserService $users)
    {
        $this->users = $users;
    }

    /** Get the currently authenticated user (roles + flattened permissions). */
    public function me()
    {
        return UserDto::from($this->users->getById((int) Auth::guard('api')->id()));
    }

    /**
     * List all users, paginated. Open to every authenticated user so the chat
     * module can pick peers; mutating endpoints require user:write.
     */
    public function index(Request $request)
    {
        $page = $this->users->list(PageQuery::fromRequest($request));
        return PageResponse::from($page, [UserDto::class, 'from']);
    }

    /** Get one user by id. Open to every authenticated user. */
    public function show(int $id)
    {
        return UserDto::from($this->users->getById($id));
    }

    /** Create a new user with bcrypt-hashed password and optional roles. */
    public function store(CreateUserRequest $request)
    {
        $user = $this->users->create([
            'email' => $request->input('email'),
            'password' => $request->input('password'),
            'fullName' => $request->input('fullName'),
            'phone' => $request->input('phone'),
            'roles' => $request->roleCodes(),
        ]);
        return UserDto::from($user);
    }

    /** Partial update — only fields present in the body are touched. */
    public function update(UpdateUserRequest $request, int $id)
    {
        $data = $request->validated();
        if (empty($data)) {
            return UserDto::from($this->users->getById($id));
        }
        return UserDto::from($this->users->update($id, $data));
    }

    /** Hard-delete a user (their refresh tokens cascade in the DB). */
    public function destroy(int $id)
    {
        $this->users->delete($id);
        return null;
    }

    /** Bulk-assign roles: mode = ADD (default) | REPLACE | REMOVE. */
    public function assignRoles(AssignRolesRequest $request)
    {
        $updated = $this->users->assignRoles(
            $request->userIds(),
            $request->roleCodes(),
            $request->mode()
        );
        return array_map([UserDto::class, 'from'], $updated);
    }
}
