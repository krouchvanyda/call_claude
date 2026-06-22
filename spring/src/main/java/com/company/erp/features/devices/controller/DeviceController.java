package com.company.erp.features.devices.controller;

import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.features.devices.dto.DeviceDto;
import com.company.erp.features.devices.dto.RegisterDeviceRequest;
import com.company.erp.features.devices.service.DeviceService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/me/devices")
public class DeviceController {

    private final DeviceService devices;

    public DeviceController(DeviceService devices) {
        this.devices = devices;
    }

    /** List my registered devices. */
    @GetMapping
    public List<DeviceDto> list() {
        Long me = AuthenticatedUser.require().userId();
        return devices.listForUser(me).stream().map(DeviceDto::from).toList();
    }

    /** Register or update this device's FCM token. Upserts on (userId, deviceId). */
    @PostMapping
    public DeviceDto register(@Valid @RequestBody RegisterDeviceRequest body) {
        Long me = AuthenticatedUser.require().userId();
        return DeviceDto.from(devices.register(me, body));
    }

    /** Revoke this device on logout or token rotation. */
    @DeleteMapping("/{deviceId}")
    public void delete(@PathVariable String deviceId) {
        Long me = AuthenticatedUser.require().userId();
        devices.delete(me, deviceId);
    }
}
