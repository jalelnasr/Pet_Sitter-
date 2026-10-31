package com.petsitter.common.exception;

/** Optional dependency is down (HTTP 503). CRUD must keep working. */
public class ServiceUnavailableException extends RuntimeException {

    private final String code;

    public ServiceUnavailableException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
