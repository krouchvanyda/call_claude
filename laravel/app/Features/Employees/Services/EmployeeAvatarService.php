<?php

namespace App\Features\Employees\Services;

use App\Features\Employees\Models\Employee;
use App\Support\Exceptions\BadRequestException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

/**
 * Server-side multipart avatar upload — files are stored on the API host's
 * filesystem and served back as static resources. Port of the Spring
 * EmployeeAvatarService.
 */
class EmployeeAvatarService
{
    /** @var EmployeeService */
    private $employees;

    /** @var string */
    private $avatarDir;

    /** @var string */
    private $publicBaseUrl;

    /** @var int */
    private $maxBytes;

    /** @var array<int, string> */
    private $allowedTypes;

    public function __construct(EmployeeService $employees)
    {
        $this->employees = $employees;
        $this->avatarDir = $this->resolveDir((string) config('erp.uploads.avatar.dir'));
        $this->publicBaseUrl = rtrim((string) config('erp.uploads.avatar.public_base_url'), '/');
        $this->maxBytes = (int) config('erp.uploads.avatar.max_file_size');
        $this->allowedTypes = array_values(array_filter(array_map('trim',
            explode(',', (string) config('erp.uploads.avatar.allowed_content_types')))));
    }

    public function uploadForEmployee(int $employeeId, ?UploadedFile $file): Employee
    {
        return $this->store($this->employees->getById($employeeId), $file);
    }

    public function uploadForCurrentUser(int $userId, ?UploadedFile $file): Employee
    {
        return $this->store($this->employees->getByUserId($userId), $file);
    }

    public function deleteForEmployee(int $employeeId): Employee
    {
        return $this->clear($this->employees->getById($employeeId));
    }

    public function deleteForCurrentUser(int $userId): Employee
    {
        return $this->clear($this->employees->getByUserId($userId));
    }

    private function store(Employee $employee, ?UploadedFile $file): Employee
    {
        if ($file === null || ! $file->isValid()) {
            throw new BadRequestException('Avatar file is required');
        }
        if ($file->getSize() > $this->maxBytes) {
            throw new BadRequestException('Avatar exceeds max size of '.$this->maxBytes.' bytes');
        }
        $contentType = $file->getClientMimeType();
        if ($contentType === null || ! in_array($contentType, $this->allowedTypes, true)) {
            throw new BadRequestException('Unsupported content type: '.$contentType
                .' (allowed: ['.implode(', ', $this->allowedTypes).'])');
        }

        $ext = $this->extensionFor($contentType);
        $filename = $employee->id.'-'.Str::uuid().'.'.$ext;

        if (! is_dir($this->avatarDir)) {
            @mkdir($this->avatarDir, 0775, true);
        }
        $file->move($this->avatarDir, $filename);

        $this->deleteFileQuietly($employee->avatar_url);
        $employee->avatar_url = $this->publicBaseUrl.'/'.$filename;
        $employee->avatar_content_type = $contentType;
        $employee->avatar_uploaded_at = Carbon::now();
        $employee->save();

        return $employee;
    }

    private function clear(Employee $employee): Employee
    {
        if ($employee->avatar_url !== null) {
            $this->deleteFileQuietly($employee->avatar_url);
            $employee->avatar_url = null;
            $employee->avatar_content_type = null;
            $employee->avatar_uploaded_at = null;
            $employee->save();
        }
        return $employee;
    }

    private function deleteFileQuietly(?string $publicUrl): void
    {
        if ($publicUrl === null || strpos($publicUrl, $this->publicBaseUrl.'/') !== 0) {
            return;
        }
        $filename = substr($publicUrl, strlen($this->publicBaseUrl.'/'));
        if (strpos($filename, '/') !== false || strpos($filename, '\\') !== false || strpos($filename, '..') !== false) {
            return;
        }
        $path = $this->avatarDir.DIRECTORY_SEPARATOR.$filename;
        if (is_file($path)) {
            @unlink($path);
        }
    }

    private function extensionFor(string $contentType): string
    {
        switch ($contentType) {
            case 'image/jpeg':
                return 'jpg';
            case 'image/png':
                return 'png';
            case 'image/webp':
                return 'webp';
            default:
                return 'bin';
        }
    }

    private function resolveDir(string $dir): string
    {
        if ($dir === '') {
            $dir = base_path('uploads/avatars');
        }
        // Absolute path stays; relative is resolved against the project root.
        if ($dir[0] !== '/' && ! preg_match('/^[A-Za-z]:[\\\\\\/]/', $dir)) {
            $dir = base_path(ltrim(preg_replace('#^\./#', '', $dir), '/'));
        }
        return rtrim($dir, '/\\');
    }
}
