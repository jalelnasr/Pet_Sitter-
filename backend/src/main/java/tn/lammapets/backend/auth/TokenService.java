package tn.lammapets.backend.auth;

import java.time.Duration;
import java.time.Instant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import tn.lammapets.backend.user.User;

@Service
public class TokenService {

	private final JwtEncoder encoder;

	private final Duration validity;

	public TokenService(JwtEncoder encoder, @Value("${app.jwt.validity-hours}") long hours) {
		this.encoder = encoder;
		this.validity = Duration.ofHours(hours);
	}

	public String issue(User user) {
		Instant now = Instant.now();
		JwtClaimsSet claims = JwtClaimsSet.builder()
			.subject(user.getId())
			.issuedAt(now)
			.expiresAt(now.plus(validity))
			.claim("role", user.getRole().name())
			.build();
		return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
	}

}
