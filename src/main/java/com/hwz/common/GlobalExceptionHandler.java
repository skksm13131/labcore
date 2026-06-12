package com.hwz.common;

import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component("learnAnalyticsGlobalExceptionHandler")
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Result<Void>> handleResponseStatus(ResponseStatusException ex) {
        LOGGER.warn("ResponseStatusException status={} reason={}", ex.getStatus(), ex.getReason());
        HttpStatus status = ex.getStatus();
        String message = ex.getReason() == null ? status.getReasonPhrase() : ex.getReason();
        return ResponseEntity.status(status)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Result.fail(message));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Result<Void>> handleIllegalArgument(IllegalArgumentException ex) {
        LOGGER.warn("IllegalArgumentException", ex);
        String message = ex.getMessage() == null ? "Invalid request" : ex.getMessage();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Result.fail(message));
    }

    @ExceptionHandler({DataIntegrityViolationException.class, DataAccessException.class})
    public ResponseEntity<Result<Void>> handleDatabase(Exception ex) {
        LOGGER.error("Database exception", ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Result.fail("Invalid request"));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Result<Void>> handleUnreadableMessage(HttpMessageNotReadableException ex) {
        LOGGER.warn("Invalid request body", ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Result.fail("Invalid request body"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<Void>> handleGeneric(Exception ex) {
        LOGGER.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Result.fail("Internal server error"));
    }
}
