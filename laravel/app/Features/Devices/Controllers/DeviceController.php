<?php

namespace App\Features\Devices\Controllers;

use App\Features\Devices\Dto\DeviceDto;
use App\Features\Devices\Requests\RegisterDeviceRequest;
use App\Features\Devices\Services\DeviceService;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

class DeviceController extends Controller
{
    /** @var DeviceService */
    private $devices;

    public function __construct(DeviceService $devices)
    {
        $this->devices = $devices;
    }

    /** List my registered devices. */
    public function index()
    {
        $me = (int) Auth::guard('api')->id();
        return $this->devices->listForUser($me)->map([DeviceDto::class, 'from'])->values()->all();
    }

    /** Register or update this device's FCM token. Upserts on (userId, deviceId). */
    public function register(RegisterDeviceRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        return DeviceDto::from($this->devices->register($me, $request->validated()));
    }

    /** Revoke this device on logout or token rotation. */
    public function destroy(string $deviceId)
    {
        $me = (int) Auth::guard('api')->id();
        $this->devices->delete($me, $deviceId);
        return null;
    }
}
