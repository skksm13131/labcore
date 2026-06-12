package com.hwz.admin.service;

import com.hwz.common.context.BaseContext;
import com.hwz.common.entity.User;
import com.hwz.common.mapper.UserMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AdminAccessService {

    private final UserMapper userMapper;

    public AdminAccessService(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    public User requireUser() {
        Long userId = BaseContext.getCurrentId();
        if (userId == null || userId <= 0) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unauthorized");
        }
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found");
        }
        if (user.getStatus() != User.Status.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "User inactive");
        }
        return user;
    }

    public User requireAdmin() {
        User user = requireUser();
        if (user.getRole() != User.Role.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
        }
        return user;
    }
}
