package tn.lammapets.backend.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import tn.lammapets.backend.auth.AuthDtos.AuthResponse;
import tn.lammapets.backend.auth.AuthDtos.LoginRequest;
import tn.lammapets.backend.auth.AuthDtos.RegisterRequest;
import tn.lammapets.backend.auth.AuthDtos.RoleRequest;
import tn.lammapets.backend.auth.AuthDtos.UserResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

	private final AuthService auth;

	public AuthController(AuthService auth) {
		this.auth = auth;
	}

	@PostMapping("/register")
	@ResponseStatus(HttpStatus.CREATED)
	AuthResponse register(@Valid @RequestBody RegisterRequest req) {
		return auth.register(req);
	}

	@PostMapping("/login")
	AuthResponse login(@Valid @RequestBody LoginRequest req) {
		return auth.login(req);
	}

	@PutMapping("/me/role")
	AuthResponse changeRole(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody RoleRequest req) {
		return auth.changeRole(jwt.getSubject(), req);
	}

	@GetMapping("/me")
	UserResponse me(@AuthenticationPrincipal Jwt jwt) {
		return auth.me(jwt.getSubject());
	}

}
