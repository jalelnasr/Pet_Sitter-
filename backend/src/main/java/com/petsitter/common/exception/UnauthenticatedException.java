package com.petsitter.common.exception;

/** Connexion requise, identifiants refusés ou jeton invalide (HTTP 401). */
public class UnauthenticatedException extends RuntimeException {

    private final String code;

    public UnauthenticatedException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
