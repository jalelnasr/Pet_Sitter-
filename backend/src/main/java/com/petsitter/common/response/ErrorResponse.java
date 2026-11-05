package com.petsitter.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.Map;

/**
 * Single JSON error shape returned by every endpoint.
 *
 * <pre>
 * {
 *   "status": 409,
 *   "code": "ACTIVE_REQUEST_ALREADY_EXISTS",
 *   "message": "You already have a pending adoption request for this listing.",
 *   "timestamp": "2026-10-30T10:15:30Z"
 * }
 * </pre>
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(
        int status,
        String code,
        String message,
        Instant timestamp,
        Map<String, String> fieldErrors
) {
    public static ErrorResponse of(int status, String code, String message) {
        return new ErrorResponse(status, code, message, Instant.now(), null);
    }

    public static ErrorResponse validation(String message, Map<String, String> fieldErrors) {
        return new ErrorResponse(400, "VALIDATION_ERROR", message, Instant.now(), fieldErrors);
    }
}
