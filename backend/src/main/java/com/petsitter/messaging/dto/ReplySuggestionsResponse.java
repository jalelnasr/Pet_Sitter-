package com.petsitter.messaging.dto;

import java.util.List;

/** Trois réponses courtes proposées par l'assistant ; {@code source} = llm, fallback ou local. */
public record ReplySuggestionsResponse(List<String> replies, String source) {
}
