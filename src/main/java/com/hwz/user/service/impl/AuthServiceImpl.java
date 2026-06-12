package com.hwz.user.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.hwz.common.auth.AccessTokenService;
import com.hwz.common.entity.RefreshToken;
import com.hwz.common.entity.User;
import com.hwz.common.mapper.RefreshTokenMapper;
import com.hwz.common.mapper.UserMapper;
import com.hwz.common.security.PasswordChangeRequiredService;
import com.hwz.common.util.PasswordSupport;
import com.hwz.user.dto.LoginRequest;
import com.hwz.user.dto.LoginResponse;
import com.hwz.user.dto.RefreshTokenRequest;
import com.hwz.user.dto.RegisterRequest;
import com.hwz.user.dto.TokenResponse;
import com.hwz.user.dto.UserInfoResponse;
import com.hwz.user.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthServiceImpl implements AuthService {

    private static final String REFRESH_PREFIX = "refresh-";
    private static final int REFRESH_DAYS = 7;
    private static final int MIN_PASSWORD_LENGTH = 12;

    private final UserMapper userMapper;
    private final RefreshTokenMapper refreshTokenMapper;
    private final PasswordEncoder passwordEncoder;
    private final AccessTokenService accessTokenService;
    private final PasswordChangeRequiredService passwordChangeRequiredService;

    public AuthServiceImpl(UserMapper userMapper,
                           RefreshTokenMapper refreshTokenMapper,
                           PasswordEncoder passwordEncoder,
                           AccessTokenService accessTokenService,
                           PasswordChangeRequiredService passwordChangeRequiredService) {
        this.userMapper = userMapper;
        this.refreshTokenMapper = refreshTokenMapper;
        this.passwordEncoder = passwordEncoder;
        this.accessTokenService = accessTokenService;
        this.passwordChangeRequiredService = passwordChangeRequiredService;
    }

    @Override
    public LoginResponse login(LoginRequest req) {
        if (req == null || !StringUtils.hasText(req.getUsername()) || !StringUtils.hasText(req.getPassword())) {
            throw new IllegalArgumentException("Username and password are required");
        }

        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getUsername, req.getUsername())
                        .last("LIMIT 1")
        );

        if (user == null || !PasswordSupport.matches(passwordEncoder, req.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid username or password");
        }

        LocalDateTime now = LocalDateTime.now();
        boolean adminFirstLogin = user.getRole() == User.Role.ADMIN && user.getLastLoginTime() == null;
        if (!PasswordSupport.isEncoded(user.getPassword())) {
            user.setPassword(passwordEncoder.encode(req.getPassword()));
        }
        user.setLastLoginTime(now);
        user.setUpdatedTime(now);
        userMapper.updateById(user);

        String accessToken = accessTokenService.issue(user.getId());
        String refreshToken = issueRefreshToken(user.getId());
        boolean mustChangePassword = user.getRole() == User.Role.ADMIN
                && (adminFirstLogin || !isStrongPassword(req.getPassword()));
        if (mustChangePassword) {
            passwordChangeRequiredService.requireChange(user.getId());
        }
        return LoginResponse.from(user, accessToken, refreshToken, mustChangePassword);
    }

    @Override
    public LoginResponse register(RegisterRequest req) {
        if (req == null || !StringUtils.hasText(req.getUsername()) || !StringUtils.hasText(req.getPassword())) {
            throw new IllegalArgumentException("Username and password are required");
        }
        validatePasswordStrength(req.getPassword());
        if (StringUtils.hasText(req.getConfirmPassword()) && !req.getPassword().equals(req.getConfirmPassword())) {
            throw new IllegalArgumentException("Password confirmation does not match");
        }

        User existing = userMapper.selectOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getUsername, req.getUsername())
                        .last("LIMIT 1")
        );
        if (existing != null) {
            throw new IllegalArgumentException("Registration failed");
        }

        String displayName = StringUtils.hasText(req.getRealName()) ? req.getRealName() : req.getUsername();
        LocalDateTime now = LocalDateTime.now();
        User user = User.builder()
                .username(req.getUsername())
                .password(passwordEncoder.encode(req.getPassword()))
                .displayName(displayName)
                .email(req.getEmail())
                .realName(req.getRealName())
                .grade(req.getGrade())
                .role(User.Role.USER)
                .status(User.Status.ACTIVE)
                .createdTime(now)
                .updatedTime(now)
                .build();
        userMapper.insert(user);

        String accessToken = accessTokenService.issue(user.getId());
        String refreshToken = issueRefreshToken(user.getId());
        return LoginResponse.from(user, accessToken, refreshToken);
    }

    @Override
    public TokenResponse refreshToken(RefreshTokenRequest req) {
        if (req == null || !StringUtils.hasText(req.getRefreshToken())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token is required");
        }

        RefreshToken token = refreshTokenMapper.selectOne(
                new LambdaQueryWrapper<RefreshToken>()
                        .eq(RefreshToken::getToken, req.getRefreshToken())
                        .isNull(RefreshToken::getRevokedAt)
                        .last("LIMIT 1")
        );

        LocalDateTime now = LocalDateTime.now();
        if (token == null || token.getExpiresAt() == null || token.getExpiresAt().isBefore(now)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token expired");
        }
        if (token.getCreatedAt() != null && token.getCreatedAt().plusDays(REFRESH_DAYS).isBefore(now)) {
            token.setRevokedAt(now);
            refreshTokenMapper.updateById(token);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token expired");
        }

        String accessToken = accessTokenService.issue(token.getUserId());
        String newRefreshToken = REFRESH_PREFIX + UUID.randomUUID();
        token.setToken(newRefreshToken);
        LocalDateTime absoluteExpiresAt = token.getCreatedAt() == null ? now.plusDays(REFRESH_DAYS) : token.getCreatedAt().plusDays(REFRESH_DAYS);
        LocalDateTime rollingExpiresAt = now.plusDays(REFRESH_DAYS);
        token.setExpiresAt(rollingExpiresAt.isBefore(absoluteExpiresAt) ? rollingExpiresAt : absoluteExpiresAt);
        refreshTokenMapper.updateById(token);

        return TokenResponse.builder()
                .token(accessToken)
                .refreshToken(newRefreshToken)
                .build();
    }

    @Override
    public UserInfoResponse getCurrentUser(String authorization) {
        Long userId = accessTokenService.verifyAndGetUserId(authorization);
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found");
        }
        return UserInfoResponse.from(user);
    }

    private String issueRefreshToken(Long userId) {
        String refreshToken = REFRESH_PREFIX + UUID.randomUUID();
        LocalDateTime now = LocalDateTime.now();
        RefreshToken record = RefreshToken.builder()
                .userId(userId)
                .token(refreshToken)
                .createdAt(now)
                .expiresAt(now.plusDays(REFRESH_DAYS))
                .build();
        refreshTokenMapper.insert(record);
        return refreshToken;
    }

    private void validatePasswordStrength(String password) {
        if (!isStrongPassword(password)) {
            if (password == null || password.length() < MIN_PASSWORD_LENGTH) {
                throw new IllegalArgumentException("Password must be at least 12 characters");
            }
            throw new IllegalArgumentException("Password must contain uppercase letters, lowercase letters, numbers, and special characters");
        }
    }

    private boolean isStrongPassword(String password) {
        if (password == null || password.length() < MIN_PASSWORD_LENGTH) {
            return false;
        }
        boolean hasLower = false;
        boolean hasUpper = false;
        boolean hasDigit = false;
        boolean hasSpecial = false;
        for (int i = 0; i < password.length(); i++) {
            char ch = password.charAt(i);
            if (Character.isLowerCase(ch)) {
                hasLower = true;
            } else if (Character.isUpperCase(ch)) {
                hasUpper = true;
            }
            if (Character.isDigit(ch)) {
                hasDigit = true;
            } else if (!Character.isLetterOrDigit(ch)) {
                hasSpecial = true;
            }
        }
        return hasLower && hasUpper && hasDigit && hasSpecial;
    }

}
