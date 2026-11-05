package com.petsitter.user.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.EnumSet;

/**
 * Temporary replacement for authentication.
 *
 * <p>Protected endpoints receive the header {@code X-Demo-User-Id} whose value
 * must be one of OWNER_DEMO, PETSITTER_DEMO or ADMIN_DEMO. This will later be
 * replaced by {@code Authorization: Bearer &lt;JWT&gt;}.</p>
 */
@Service
public class DemoUserResolver {

    public static final String HEADER = "X-Demo-User-Id";

    private final UserRepository users;

    public DemoUserResolver(UserRepository users) {
        this.users = users;
    }

    @Transactional(readOnly = true)
    public UserEntity require(String demoUserId) {
        if (demoUserId == null || demoUserId.isBlank()) {
            throw new BadRequestException(
                    "DEMO_USER_REQUIRED",
                    "The X-Demo-User-Id header is required for this endpoint."
            );
        }
        return users.findById(demoUserId.trim())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Demo user not found: " + demoUserId));
    }

    /**
     * Resolves an optional header value. Used by public endpoints that show
     * slightly more data to the publisher or to an administrator.
     */
    @Transactional(readOnly = true)
    public UserEntity optional(String demoUserId) {
        if (demoUserId == null || demoUserId.isBlank()) {
            return null;
        }
        return require(demoUserId);
    }

    @Transactional(readOnly = true)
    public UserEntity requireRole(String demoUserId, UserRole... allowed) {
        UserEntity user = require(demoUserId);
        if (!EnumSet.copyOf(Arrays.asList(allowed)).contains(user.getRole())) {
            throw new UnauthorizedActionException(
                    "Your role is not allowed to perform this operation.");
        }
        return user;
    }
}
