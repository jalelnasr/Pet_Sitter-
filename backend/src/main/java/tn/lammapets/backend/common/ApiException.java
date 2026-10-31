package tn.lammapets.backend.common;

import org.springframework.http.HttpStatus;

/** Erreur métier : le message est affiché tel quel à l'utilisateur. */
public class ApiException extends RuntimeException {

	private final HttpStatus status;

	public ApiException(HttpStatus status, String message) {
		super(message);
		this.status = status;
	}

	public HttpStatus getStatus() {
		return status;
	}

}
