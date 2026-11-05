package com.petsitter.event.security;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.service.DemoUserResolver;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

@Component
public class EventUserResolver {

    public static final String USER_ID_HEADER = "X-User-Id";
    public static final String LEGACY_USER_ID_HEADER = "X-Demo-User-Id";
    public static final String DEFAULT_USER_ID = "OWNER_DEMO";

    private final DemoUserResolver demoUsers;

    public EventUserResolver(DemoUserResolver demoUsers) {
        this.demoUsers = demoUsers;
    }

    public UserEntity resolve(HttpServletRequest request) {
        String header = request.getHeader(USER_ID_HEADER);
        if (header == null || header.isBlank()) {
            header = request.getHeader(LEGACY_USER_ID_HEADER);
        }
        String userId = (header != null && !header.isBlank()) ? header.trim() : DEFAULT_USER_ID;
        return demoUsers.require(userId);
    }

    public UserEntity resolveFromHeader(String headerValue) {
        String userId = (headerValue != null && !headerValue.isBlank()) ? headerValue.trim() : DEFAULT_USER_ID;
        return demoUsers.require(userId);
    }
}
