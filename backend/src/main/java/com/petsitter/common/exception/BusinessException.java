package com.petsitter.common.exception;

/**
 * Business-rule conflict, for example a duplicate pending request or an
 * invalid status transition (HTTP 409).
 */
public class BusinessException extends RuntimeException {

    private final String code;

    public BusinessException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
