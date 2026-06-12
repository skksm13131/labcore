package com.hwz.common.security;

import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class PasswordChangeRequiredService {

    private final Set<Long> requiredUserIds = ConcurrentHashMap.newKeySet();

    public void requireChange(Long userId) {
        if (userId != null) {
            requiredUserIds.add(userId);
        }
    }

    public void clear(Long userId) {
        if (userId != null) {
            requiredUserIds.remove(userId);
        }
    }

    public boolean isRequired(Long userId) {
        return userId != null && requiredUserIds.contains(userId);
    }
}
