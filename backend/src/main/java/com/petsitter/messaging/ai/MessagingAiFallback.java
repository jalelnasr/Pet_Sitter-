package com.petsitter.messaging.ai;

import com.petsitter.messaging.enums.MessageRisk;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Règles locales du backend, utilisées quand le service Python {@code messaging_ai} est arrêté.
 * Reprend l'essentiel des règles de {@code messaging_ai/rules.py} : la messagerie reste protégée.
 */
public final class MessagingAiFallback {

    private static final List<Pattern> PAYMENT_HIGH = compile(
            "western\\s*union", "money\\s*gram", "mandat cash", "code (de (la|ta|votre) )?carte", "\\bcvv\\b",
            "code secret", "code pin", "numero de (la |ta |votre )?carte", "payer? (d'avance|en avance|avant)",
            "paiement (d'avance|hors)", "envoie[sz]?(-moi| moi)? (l'|de l')?argent", "envoyer (l'|de l')?argent",
            "recharge (orange|ooredoo|telecom)", "carte (cadeau|google play|itunes)", "bitcoin", "crypto");
    private static final List<Pattern> PAYMENT_LOW = compile(
            "\\bd17\\b", "flouci", "\\brib\\b", "\\biban\\b", "virement", "paypal");
    private static final Pattern URL = Pattern.compile("(https?://|www\\.)\\S+", Pattern.CASE_INSENSITIVE);
    private static final Pattern SHORTENER = Pattern.compile("(bit\\.ly|tinyurl|goo\\.gl|t\\.co/|cutt\\.ly)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern PHONE = Pattern.compile("(\\+?216[\\s.-]?)?\\b[2-9]\\d(?:[\\s.-]?\\d){6}\\b");
    private static final Pattern EMAIL = Pattern.compile("[\\w.+-]+@[\\w-]+\\.[\\w.]+");

    static final Map<String, String> REASONS = Map.of(
            "ARNAQUE_PAIEMENT", "Demande de paiement hors de l'application ou de coordonnées bancaires : ne payez "
                    + "jamais à l'avance par transfert d'argent et ne partagez jamais le code de votre carte.",
            "PAIEMENT_EXTERNE", "Paiement hors de l'application : réglez de préférence via Pet Sitter, où la garde "
                    + "est protégée.",
            "INSULTE", "Ce message contient des propos insultants. Restez courtois : les messages irrespectueux "
                    + "peuvent être signalés.",
            "GROSSIERETE", "Langage grossier : restez courtois avec les autres membres.",
            "LIEN_SUSPECT", "Lien raccourci ou inconnu : n'ouvrez pas de lien et ne saisissez pas vos identifiants "
                    + "si vous n'êtes pas sûr de l'expéditeur.",
            "COORDONNEES", "Coordonnées personnelles partagées : gardez les échanges dans la messagerie jusqu'à la "
                    + "confirmation de la garde.");
    private static final Set<String> HIGH = Set.of("ARNAQUE_PAIEMENT", "INSULTE");

    private MessagingAiFallback() {
    }

    public static MessageAnalysis analyze(String text) {
        String t = normalize(text);
        List<String> categories = new ArrayList<>();
        if (matchesAny(PAYMENT_HIGH, t)) {
            categories.add("ARNAQUE_PAIEMENT");
        } else if (matchesAny(PAYMENT_LOW, t)) {
            categories.add("PAIEMENT_EXTERNE");
        }
        Map<String, String> details = new java.util.HashMap<>();
        List<ProfanityDetector.Hit> hits = ProfanityDetector.instance().find(text);
        List<ProfanityDetector.Hit> high = hits.stream().filter(h -> h.term().isHigh()).toList();
        List<ProfanityDetector.Hit> low = hits.stream().filter(h -> !h.term().isHigh()).toList();
        if (!high.isEmpty()) {
            categories.add("INSULTE");
            details.put("INSULTE", "Gros mot ou insulte détecté (" + describe(high) + "). Restez courtois : "
                    + "les messages irrespectueux peuvent être signalés.");
        } else if (!low.isEmpty()) {
            categories.add("GROSSIERETE");
            details.put("GROSSIERETE", "Langage grossier (" + describe(low)
                    + ") : restez courtois avec les autres membres.");
        }
        if (URL.matcher(text).find() && SHORTENER.matcher(text).find()) {
            categories.add("LIEN_SUSPECT");
        }
        if (PHONE.matcher(text).find() || EMAIL.matcher(text).find()) {
            categories.add("COORDONNEES");
        }
        return build(categories, "local", details);
    }

    /** « « m****n » et « t***n », tunisien » ; deux mots au plus, regroupés par langue, jamais en clair. */
    static String describe(List<ProfanityDetector.Hit> hits) {
        ProfanityDetector detector = ProfanityDetector.instance();
        Map<String, List<String>> byLang = new java.util.LinkedHashMap<>();
        hits.stream().limit(2).forEach(h -> byLang
                .computeIfAbsent(detector.languageName(h.term().lang()), k -> new ArrayList<>())
                .add("« " + h.masked() + " »"));
        return byLang.entrySet().stream()
                .map(e -> String.join(" et ", e.getValue()) + ", " + e.getKey())
                .collect(java.util.stream.Collectors.joining(" ; "));
    }

    /** Construit le résultat à partir de catégories (inconnues ignorées), la plus grave expliquée. */
    public static MessageAnalysis build(List<String> rawCategories, String source) {
        return build(rawCategories, source, Map.of());
    }

    /** {@code details} : explication précise par catégorie (mot masqué, langue), sinon la raison générale. */
    public static MessageAnalysis build(List<String> rawCategories, String source, Map<String, String> details) {
        List<String> categories = new ArrayList<>(new LinkedHashSet<>(
                rawCategories == null ? List.of() : rawCategories.stream().filter(REASONS::containsKey).toList()));
        if (categories.isEmpty()) {
            return new MessageAnalysis(MessageRisk.NONE, List.of(), "", source);
        }
        boolean high = categories.stream().anyMatch(HIGH::contains);
        String main = categories.stream().filter(HIGH::contains).findFirst().orElse(categories.get(0));
        String reason = details != null && details.containsKey(main) ? details.get(main) : REASONS.get(main);
        return new MessageAnalysis(high ? MessageRisk.HIGH : MessageRisk.LOW, categories, reason, source);
    }

    /** Réponses génériques selon le dernier message reçu (sans IA). */
    public static List<String> suggest(String lastReceived, boolean petsitter) {
        String t = normalize(lastReceived == null ? "" : lastReceived);
        if (t.isBlank()) {
            return List.of("Bonjour ! Comment puis-je vous aider ?", "Bonjour, quelles sont vos disponibilités ?",
                    "Bonjour ! Pouvez-vous m'en dire plus ?");
        }
        if (t.matches(".*(merci|super|parfait|genial).*")) {
            return List.of("Avec plaisir !", "Je vous en prie, à bientôt !", "N'hésitez pas si vous avez une question.");
        }
        if (t.matches(".*(dispo|disponible|libre|week-?end).*")) {
            return petsitter
                    ? List.of("Oui, je suis disponible à ces dates.", "Pouvez-vous me préciser les dates exactes ?",
                    "Désolé, je ne suis pas disponible à ces dates.")
                    : List.of("Les dates me conviennent, merci !", "Pouvons-nous décaler d'un jour ?",
                    "Je vous confirme les dates dès que possible.");
        }
        if (t.matches(".*(prix|tarif|combien|cout).*")) {
            return petsitter
                    ? List.of("Mon tarif est indiqué sur mon profil.", "Combien d'animaux et combien de jours ?",
                    "Je peux vous faire un devis précis.")
                    : List.of("D'accord, ça me convient.", "Le tarif comprend-il les promenades ?",
                    "Pouvez-vous me faire un devis ?");
        }
        return List.of("D'accord, merci !", "Je vous réponds dès que possible.", "Pouvez-vous m'en dire plus ?");
    }

    static String normalize(String text) {
        String lower = text.replace('’', '\'').toLowerCase();
        return Normalizer.normalize(lower, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
    }

    private static boolean matchesAny(List<Pattern> patterns, String text) {
        return patterns.stream().anyMatch(p -> p.matcher(text).find());
    }

    private static List<Pattern> compile(String... regexes) {
        return java.util.Arrays.stream(regexes).map(Pattern::compile).toList();
    }
}
