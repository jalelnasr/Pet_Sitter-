package com.petsitter.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Réponse simple : un message lisible et, au besoin, un délai avant de réessayer. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record InfoResponse(String message, Integer retryAfterSeconds) {

    public static InfoResponse of(String message) {
        return new InfoResponse(message, null);
    }
}
