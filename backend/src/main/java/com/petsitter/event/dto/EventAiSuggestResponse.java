package com.petsitter.event.dto;

import java.util.List;

public record EventAiSuggestResponse(
        List<String> titles,
        String description,
        String summary,
        List<String> tags,
        List<String> checklist,
        String suggestedCategory,
        String tip,
        String source
) {}
