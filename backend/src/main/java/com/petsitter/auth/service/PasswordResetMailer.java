package com.petsitter.auth.service;

import com.petsitter.user.entity.UserEntity;
import jakarta.mail.AuthenticationFailedException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

import java.nio.charset.StandardCharsets;

/**
 * Envoie le code de réinitialisation par e-mail.
 *
 * <p>Sans serveur SMTP configuré (voir {@code backend/mail.properties.example}), ou si
 * l'envoi échoue, le code est écrit dans la console du backend quand
 * {@code petsitter.auth.log-reset-codes=true} (développement). La demande n'échoue
 * jamais côté client : l'utilisateur ne doit pas savoir si l'adresse existe.</p>
 */
@Component
public class PasswordResetMailer {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetMailer.class);

    private final ObjectProvider<JavaMailSender> mailSender;
    private final String from;
    private final String smtpHost;
    private final boolean logCodes;

    public PasswordResetMailer(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${petsitter.mail.from:no-reply@petsitter.tn}") String from,
            @Value("${spring.mail.host:}") String smtpHost,
            @Value("${petsitter.auth.log-reset-codes:true}") boolean logCodes) {
        this.mailSender = mailSender;
        this.from = from;
        this.smtpHost = smtpHost;
        this.logCodes = logCodes;
    }

    /**
     * Indique au démarrage si les codes partiront vraiment par e-mail, en vérifiant la
     * connexion et l'identifiant SMTP (sans envoyer de message).
     */
    @EventListener(ApplicationReadyEvent.class)
    public void reportConfiguration() {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null) {
            log.warn("E-mail non configuré : les codes « mot de passe oublié » sont seulement écrits dans cette "
                    + "console. Pour les envoyer, copier backend/mail.properties.example en backend/mail.properties.");
            return;
        }
        if (!(sender instanceof JavaMailSenderImpl impl)) {
            log.info("E-mail configuré : codes de réinitialisation envoyés via {} depuis {}", smtpHost, from);
            return;
        }
        try {
            impl.testConnection();
            log.info("E-mail configuré et connexion SMTP vérifiée : codes envoyés via {} depuis {}", smtpHost, from);
        } catch (Exception e) {
            Throwable root = rootCause(e);
            if (root instanceof AuthenticationFailedException) {
                log.error("E-mail : {} refuse l'identifiant ou le mot de passe de backend/mail.properties. Avec "
                        + "Gmail, il faut un « mot de passe d'application » valide. Les codes seront écrits dans "
                        + "cette console en attendant.", smtpHost);
            } else {
                log.error("E-mail : connexion impossible à {} ({}). Les codes seront écrits dans cette console.",
                        smtpHost, root.getMessage());
            }
        }
    }

    public void sendResetCode(UserEntity user, String code, long validityMinutes) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender != null) {
            try {
                sender.send(buildMessage(sender, user, code, validityMinutes));
                log.info("Code de réinitialisation envoyé par e-mail à l'utilisateur {}", user.getId());
                return;
            } catch (MailAuthenticationException e) {
                log.error("Le serveur SMTP {} a refusé l'identifiant ou le mot de passe. Avec Gmail, utilisez un "
                        + "« mot de passe d'application » (validation en deux étapes requise), pas le mot de passe "
                        + "du compte.", smtpHost);
            } catch (Exception e) {
                Throwable root = rootCause(e);
                if (root instanceof AuthenticationFailedException) {
                    log.error("Le serveur SMTP {} a refusé l'identifiant ou le mot de passe : {}", smtpHost,
                            root.getMessage());
                } else {
                    log.error("Échec de l'envoi de l'e-mail de réinitialisation via {} : {}", smtpHost,
                            root.getMessage());
                }
            }
        }
        if (logCodes) {
            log.warn("[DEV] Code de réinitialisation pour {} : {} (valable {} min)",
                    user.getEmail(), code, validityMinutes);
        }
    }

    private MimeMessage buildMessage(JavaMailSender sender, UserEntity user, String code, long minutes)
            throws Exception {
        MimeMessage message = sender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
        helper.setFrom(from);
        helper.setTo(user.getEmail());
        helper.setSubject("Pet Sitter — votre code : " + code);
        String name = user.getFirstName();
        String text = """
                Bonjour %s,

                Voici votre code pour choisir un nouveau mot de passe : %s

                Il reste valable %d minutes. Si vous n'êtes pas à l'origine de cette demande,
                ignorez simplement ce message : votre mot de passe ne change pas.

                L'équipe Pet Sitter
                """.formatted(name, code, minutes);
        String html = """
                <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;color:#151816">
                  <h2 style="color:#0F5534">Pet Sitter</h2>
                  <p>Bonjour %s,</p>
                  <p>Voici votre code pour choisir un nouveau mot de passe :</p>
                  <p style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#0F5534;
                            background:#FFFAF0;padding:16px;text-align:center;border-radius:12px">%s</p>
                  <p>Il reste valable %d minutes.</p>
                  <p style="color:#5C6461;font-size:13px">Si vous n'êtes pas à l'origine de cette demande,
                     ignorez ce message : votre mot de passe ne change pas.</p>
                </div>
                """.formatted(HtmlUtils.htmlEscape(name), code, minutes);
        helper.setText(text, html);
        return message;
    }

    private static Throwable rootCause(Throwable e) {
        Throwable current = e;
        while (current.getCause() != null && current.getCause() != current) {
            current = current.getCause();
        }
        return current;
    }
}
