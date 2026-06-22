package com.company.erp.features.devices.entity;

import com.company.erp.core.database.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "devices",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "device_id"}))
public class Device extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Mobile-supplied stable install id (per app install, not per session). */
    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Column(name = "fcm_token", nullable = false, columnDefinition = "TEXT")
    private String fcmToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DevicePlatform platform;

    @Column(name = "app_version")
    private String appVersion;
}
