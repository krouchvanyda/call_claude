package com.company.erp.features.employees.service;

import com.company.erp.core.config.AppProperties;
import com.company.erp.core.exceptions.BadRequestException;
import com.company.erp.features.employees.entity.Employee;
import com.company.erp.features.employees.repository.EmployeeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class EmployeeAvatarService {

    private final EmployeeService employees;
    private final EmployeeRepository employeeRepo;
    private final Path avatarDir;
    private final String publicBaseUrl;
    private final long maxBytes;
    private final Set<String> allowedTypes;

    public EmployeeAvatarService(EmployeeService employees,
                                 EmployeeRepository employeeRepo,
                                 AppProperties props) {
        this.employees = employees;
        this.employeeRepo = employeeRepo;
        AppProperties.Uploads.Avatar cfg = props.uploads().avatar();
        this.avatarDir     = Paths.get(cfg.dir()).toAbsolutePath().normalize();
        this.publicBaseUrl = trimTrailingSlash(cfg.publicBaseUrl());
        this.maxBytes      = cfg.maxFileSize();
        this.allowedTypes  = Arrays.stream(cfg.allowedContentTypes().split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toUnmodifiableSet());
    }

    public Employee uploadForEmployee(Long employeeId, MultipartFile file) {
        Employee employee = employees.getById(employeeId);
        return store(employee, file);
    }

    public Employee uploadForCurrentUser(Long userId, MultipartFile file) {
        Employee employee = employees.getByUserId(userId);
        return store(employee, file);
    }

    public Employee deleteForEmployee(Long employeeId) {
        return clear(employees.getById(employeeId));
    }

    public Employee deleteForCurrentUser(Long userId) {
        return clear(employees.getByUserId(userId));
    }

    private Employee store(Employee employee, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Avatar file is required");
        }
        if (file.getSize() > maxBytes) {
            throw new BadRequestException("Avatar exceeds max size of " + maxBytes + " bytes");
        }
        String contentType = file.getContentType();
        if (contentType == null || !allowedTypes.contains(contentType)) {
            throw new BadRequestException("Unsupported content type: " + contentType
                    + " (allowed: " + allowedTypes + ")");
        }

        String ext = extensionFor(contentType);
        String filename = employee.getId() + "-" + UUID.randomUUID() + "." + ext;
        Path target = avatarDir.resolve(filename);

        try {
            Files.createDirectories(avatarDir);
            try (var in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to store avatar: " + ex.getMessage(), ex);
        }

        deleteFileQuietly(employee.getAvatarUrl());
        employee.setAvatarUrl(publicBaseUrl + "/" + filename);
        employee.setAvatarContentType(contentType);
        employee.setAvatarUploadedAt(Instant.now());
        return employeeRepo.save(employee);
    }

    private Employee clear(Employee employee) {
        if (employee.getAvatarUrl() != null) {
            deleteFileQuietly(employee.getAvatarUrl());
            employee.setAvatarUrl(null);
            employee.setAvatarContentType(null);
            employee.setAvatarUploadedAt(null);
        }
        return employee;
    }

    private void deleteFileQuietly(String publicUrl) {
        if (publicUrl == null || !publicUrl.startsWith(publicBaseUrl + "/")) return;
        String filename = publicUrl.substring((publicBaseUrl + "/").length());
        if (filename.contains("/") || filename.contains("\\") || filename.contains("..")) return;
        try {
            Files.deleteIfExists(avatarDir.resolve(filename));
        } catch (IOException ignored) {
            // best-effort cleanup; missing files are not fatal
        }
    }

    private static String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/jpeg" -> "jpg";
            case "image/png"  -> "png";
            case "image/webp" -> "webp";
            default           -> "bin";
        };
    }

    private static String trimTrailingSlash(String s) {
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }
}
