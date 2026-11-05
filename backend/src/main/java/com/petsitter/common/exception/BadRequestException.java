package com.petsitter.common.exception;

/** Invalid payload or missing required request data (HTTP 400). */
public class BadRequestException extends RuntimeException {

    private final String code;

    public BadRequestException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
