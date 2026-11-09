package com.petsitter.auth.dto;

/** Règles de mot de passe partagées par l'inscription, le changement et la réinitialisation. */
public final class PasswordPolicy {

    /** Au moins 8 caractères dont un chiffre ; 72 au plus (limite de BCrypt). */
    public static final String REGEX = "^(?=.*\\d).{8,72}$";
    public static final String MESSAGE = "Au moins 8 caractères, dont un chiffre.";

    private PasswordPolicy() {
    }
}
