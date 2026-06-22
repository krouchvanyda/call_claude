package com.company.erp.features.devices.repository;

import com.company.erp.features.devices.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceRepository extends JpaRepository<Device, Long> {

    Optional<Device> findByUserIdAndDeviceId(Long userId, String deviceId);

    List<Device> findByUserId(Long userId);

    List<Device> findByUserIdIn(List<Long> userIds);

    void deleteByUserIdAndDeviceId(Long userId, String deviceId);
}
