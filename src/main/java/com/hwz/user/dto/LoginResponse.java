package com.hwz.user.dto;

import com.hwz.common.entity.User;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LoginResponse {
    private String token;
    private String refreshToken;
    private Long userId;
    private String username;
    private String displayName;
    private User.Role role;
    private boolean mustChangePassword;

    public static LoginResponse from(User user, String token, String refreshToken) {
        return from(user, token, refreshToken, false);
    }

    public static LoginResponse from(User user, String token, String refreshToken, boolean mustChangePassword) {
        return LoginResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .role(user.getRole())
                .mustChangePassword(mustChangePassword)
                .build();
    }
}
