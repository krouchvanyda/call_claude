package com.company.erp.features.devices.dto;

import com.company.erp.features.devices.entity.Device;
import com.company.erp.features.devices.entity.DevicePlatform;

import java.time.Instant;

public record DeviceDto(
        Long id,
        String deviceId,
        DevicePlatform platform,
        String appVersion,
        Instant updatedAt
) {
    public static DeviceDto from(Device d) {
        return new DeviceDto(d.getId(), d.getDeviceId(), d.getPlatform(),
                d.getAppVersion(), d.getUpdatedAt());
    }
}
