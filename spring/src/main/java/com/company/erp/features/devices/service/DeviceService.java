package com.company.erp.features.devices.service;

import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.devices.dto.RegisterDeviceRequest;
import com.company.erp.features.devices.entity.Device;
import com.company.erp.features.devices.repository.DeviceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class DeviceService {

    private final DeviceRepository devices;

    public DeviceService(DeviceRepository devices) {
        this.devices = devices;
    }

    /** Upsert by (userId, deviceId) — token rotation overwrites the row in place. */
    public Device register(Long userId, RegisterDeviceRequest req) {
        Device d = devices.findByUserIdAndDeviceId(userId, req.deviceId())
                .orElseGet(Device::new);
        d.setUserId(userId);
        d.setDeviceId(req.deviceId());
        d.setFcmToken(req.fcmToken());
        d.setPlatform(req.platform());
        d.setAppVersion(req.appVersion());
        return devices.save(d);
    }

    public void delete(Long userId, String deviceId) {
        Device d = devices.findByUserIdAndDeviceId(userId, deviceId)
                .orElseThrow(() -> new NotFoundException("Device not registered"));
        devices.delete(d);
    }

    @Transactional(readOnly = true)
    public List<Device> listForUser(Long userId) {
        return devices.findByUserId(userId);
    }

    @Transactional(readOnly = true)
    public List<Device> listForUsers(List<Long> userIds) {
        return userIds.isEmpty() ? List.of() : devices.findByUserIdIn(userIds);
    }
}
