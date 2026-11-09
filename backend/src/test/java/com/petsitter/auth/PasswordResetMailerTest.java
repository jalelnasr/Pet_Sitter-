package com.petsitter.auth;

import com.petsitter.auth.service.PasswordResetMailer;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.javamail.JavaMailSender;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** L'e-mail du code de réinitialisation : destinataire, expéditeur, code, texte + HTML, échecs sans erreur. */
class PasswordResetMailerTest {

    private final UserEntity user = new UserEntity("u1", "Inès", "ines@exemple.tn", UserRole.OWNER);

    @SuppressWarnings("unchecked")
    private static ObjectProvider<JavaMailSender> provider(JavaMailSender sender) {
        ObjectProvider<JavaMailSender> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(sender);
        return provider;
    }

    private static JavaMailSender senderWithRealMessages() {
        JavaMailSender sender = mock(JavaMailSender.class);
        when(sender.createMimeMessage()).thenAnswer(i -> new MimeMessage(Session.getInstance(new Properties())));
        return sender;
    }

    @Test
    @DisplayName("envoie un e-mail texte + HTML contenant le code, au titulaire du compte")
    void sendsCodeByEmail() throws Exception {
        JavaMailSender sender = senderWithRealMessages();
        new PasswordResetMailer(provider(sender), "Pet Sitter <envoi@exemple.tn>", "smtp.exemple.tn", true)
                .sendResetCode(user, "482913", 15);

        ArgumentCaptor<MimeMessage> sent = ArgumentCaptor.forClass(MimeMessage.class);
        verify(sender).send(sent.capture());
        MimeMessage message = sent.getValue();
        message.saveChanges();
        assertThat(message.getAllRecipients()[0].toString()).isEqualTo("ines@exemple.tn");
        assertThat(message.getFrom()[0].toString()).contains("envoi@exemple.tn");
        assertThat(message.getSubject()).contains("482913");
        assertThat(message.getContent()).isInstanceOf(MimeMultipart.class);

        ByteArrayOutputStream raw = new ByteArrayOutputStream();
        message.writeTo(raw);
        String body = raw.toString(StandardCharsets.UTF_8);
        assertThat(body).contains("text/plain").contains("text/html").contains("482913");
    }

    @Test
    @DisplayName("sans SMTP configuré, rien n'est envoyé et la demande ne plante pas")
    void noSmtpConfigured() {
        assertThatCode(() -> new PasswordResetMailer(provider(null), "x@exemple.tn", "", true)
                .sendResetCode(user, "123456", 15)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("identifiants SMTP refusés (Gmail) : pas d'exception remontée au client")
    void smtpAuthenticationFailure() {
        JavaMailSender sender = senderWithRealMessages();
        doThrow(new MailAuthenticationException("535 Username and Password not accepted"))
                .when(sender).send(any(MimeMessage.class));
        assertThatCode(() -> new PasswordResetMailer(provider(sender), "x@gmail.com", "smtp.gmail.com", true)
                .sendResetCode(user, "123456", 15)).doesNotThrowAnyException();
        verify(sender, never()).send(any(org.springframework.mail.SimpleMailMessage.class));
    }
}
