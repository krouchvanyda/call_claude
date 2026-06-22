package com.company.erp.features.users.repository;

import com.company.erp.features.users.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    @EntityGraph(attributePaths = {"roles", "roles.permissions"})
    Optional<User> findByEmail(String email);

    @EntityGraph(attributePaths = {"roles", "roles.permissions"})
    Optional<User> findWithRolesById(Long id);

    @EntityGraph(attributePaths = {"roles", "roles.permissions"})
    Page<User> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = {"roles", "roles.permissions"})
    List<User> findAllWithRolesByIdIn(Collection<Long> ids);

    boolean existsByEmail(String email);
}
