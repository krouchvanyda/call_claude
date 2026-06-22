package com.company.erp.features.devices.dto;

import com.company.erp.features.devices.entity.DevicePlatform;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterDeviceRequest(
        @NotBlank @Size(max = 128) String deviceId,
        @NotBlank                   String fcmToken,
        @NotNull  DevicePlatform    platform,
        @Size(max = 32)             String appVersion
) {
}
