package com.petsitter.common.exception;

/** The current user is not allowed to perform the operation (HTTP 403). */
public class UnauthorizedActionException extends RuntimeException {

    public UnauthorizedActionException(String message) {
        super(message);
    }
}
