package com.petsitter.messaging.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Détection des gros mots en plusieurs langues : français, anglais, arabe, tunisien (lettres arabes et
 * arabizi), italien, espagnol. Même algorithme et même liste que {@code messaging_ai/profanity.py}
 * (fichier {@code messaging/profanity.json}, copie de {@code messaging_ai/profanity.json}).
 *
 * <p>Résiste aux accents, majuscules, lettres répétées, tashkeel/tatweel, chiffres et symboles
 * (« c0nnard », « $alope »), lettres séparées (« p u t e ») et étoiles (« f*ck »). La comparaison
 * se fait mot par mot : « conseil » ou « Nicolas » ne sont jamais signalés.</p>
 */
public final class ProfanityDetector {

    private static final Map<Character, String> ARABIC = Map.of(
            'أ', "ا", 'إ', "ا", 'آ', "ا", 'ٱ', "ا", 'ى', "ي", 'ة', "ه", 'ؤ', "و", 'ئ', "ي", 'ـ', "");
    private static final Map<Character, Character> LEET = Map.of(
            '0', 'o', '1', 'i', '3', 'e', '4', 'a', '5', 's', '7', 't', '@', 'a', '$', 's', '€', 'e', '!', 'i');
    private static final Pattern TOKEN = Pattern.compile("[\\p{L}\\p{N}_*@$€!]+");
    private static final Pattern REPEATS = Pattern.compile("([^*])\\1+");

    /** Terme de la liste : un mot ou une expression ; {@code stem} = le dernier mot est un radical. */
    public record Term(List<String> words, boolean stem, String lang, String level, String text) {
        public boolean isHigh() {
            return "high".equals(level);
        }
    }

    /** Terme trouvé, mot(s) du message correspondants (forme normalisée) et position dans le message. */
    public record Hit(Term term, String matched, int index) {
        /** « c****d », « ya 7**r » : les petits mots d'une expression restent lisibles. */
        public String masked() {
            String[] words = matched.split(" ");
            if (words.length == 1) {
                return mask(words[0], false);
            }
            List<String> out = new ArrayList<>();
            for (String w : words) {
                out.add(mask(w, true));
            }
            return String.join(" ", out);
        }
    }

    private static final ProfanityDetector DEFAULT = load();

    private final Map<String, String> languages;
    private final List<Term> terms;

    private ProfanityDetector(Map<String, String> languages, List<Term> terms) {
        this.languages = languages;
        this.terms = terms;
    }

    public static ProfanityDetector instance() {
        return DEFAULT;
    }

    static ProfanityDetector load() {
        try (InputStream in = ProfanityDetector.class.getResourceAsStream("/messaging/profanity.json")) {
            if (in == null) {
                throw new IllegalStateException("messaging/profanity.json introuvable dans le classpath");
            }
            JsonNode root = new ObjectMapper().readTree(in);
            Map<String, String> languages = new LinkedHashMap<>();
            root.path("languages").fields().forEachRemaining(e -> languages.put(e.getKey(), e.getValue().asText()));
            List<Term> terms = new ArrayList<>();
            root.path("words").fields().forEachRemaining(lang -> {
                for (String level : List.of("high", "low")) {
                    for (JsonNode raw : lang.getValue().path(level)) {
                        String text = raw.asText();
                        boolean stem = text.endsWith("*");
                        List<String> words = tokens(stem ? text.substring(0, text.length() - 1) : text);
                        if (!words.isEmpty()) {
                            terms.add(new Term(words, stem, lang.getKey(), level, text));
                        }
                    }
                }
            });
            // Les insultes d'abord : un mot présent dans les deux niveaux compte comme insulte.
            terms.sort(Comparator.comparingInt(t -> t.isHigh() ? 0 : 1));
            return new ProfanityDetector(languages, List.copyOf(terms));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** Mot du message : forme normalisée et position [start, end) dans le texte d'origine. */
    record Tok(String text, int start, int end) {
    }

    /** Les deux lectures du message : telle quelle (arabizi) et avec traduction du « leet » (c0nnard). */
    private static List<List<Tok>> variants(String text) {
        List<Tok> base = tokenize(text);
        List<Tok> leet = base.stream().map(t -> new Tok(leet(t.text()), t.start(), t.end())).toList();
        return leet.equals(base) ? List.of(base) : List.of(base, leet);
    }

    private static boolean matchesAt(List<Tok> toks, int i, Term term) {
        int n = term.words().size();
        for (int k = 0; k < n; k++) {
            if (!tokenMatches(toks.get(i + k).text(), term.words().get(k), term.stem() && k == n - 1)) {
                return false;
            }
        }
        return true;
    }

    /**
     * Remplace chaque gros mot par des étoiles, en gardant sa première et sa dernière lettre :
     * « Si zebi » → « Si z**i », « T'es un c0nnard! » → « T'es un c*****d! », « ya 7mar » → « ya 7**r ».
     * Toutes les occurrences sont masquées ; le reste du message est inchangé.
     */
    public String censor(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        List<int[]> spans = new ArrayList<>();
        for (List<Tok> toks : variants(text)) {
            for (Term term : terms) {
                int n = term.words().size();
                for (int i = 0; i + n <= toks.size(); i++) {
                    if (!matchesAt(toks, i, term)) {
                        continue;
                    }
                    for (int k = 0; k < n; k++) {
                        Tok t = toks.get(i + k);
                        // Dans une expression, les petits mots restent lisibles (« ya », « يا », « de »).
                        if (n == 1 || t.text().codePointCount(0, t.text().length()) > 2) {
                            spans.add(new int[]{t.start(), t.end()});
                        }
                    }
                }
            }
        }
        if (spans.isEmpty()) {
            return text;
        }
        // Passages qui se chevauchent fusionnés, puis masqués de droite à gauche (positions stables).
        spans.sort(Comparator.comparingInt((int[] s) -> s[0]));
        List<int[]> merged = new ArrayList<>();
        for (int[] s : spans) {
            int[] last = merged.isEmpty() ? null : merged.get(merged.size() - 1);
            if (last != null && s[0] < last[1]) {
                last[1] = Math.max(last[1], s[1]);
            } else {
                merged.add(new int[]{s[0], s[1]});
            }
        }
        StringBuilder out = new StringBuilder(text);
        for (int j = merged.size() - 1; j >= 0; j--) {
            int[] s = merged.get(j);
            out.replace(s[0], s[1], mask(text.substring(s[0], s[1]), false));
        }
        return out.toString();
    }

    public List<Hit> find(String text) {
        List<List<String>> variants = variants(text).stream()
                .map(toks -> toks.stream().map(Tok::text).toList())
                .toList();
        List<Hit> hits = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (List<String> toks : variants) {
            for (Term term : terms) {
                int n = term.words().size();
                for (int i = 0; i + n <= toks.size(); i++) {
                    boolean ok = true;
                    for (int k = 0; k < n && ok; k++) {
                        ok = tokenMatches(toks.get(i + k), term.words().get(k), term.stem() && k == n - 1);
                    }
                    String matched = String.join(" ", toks.subList(i, i + n));
                    if (ok && !seen.contains(term.text()) && !seen.contains(matched)) {
                        seen.add(term.text());
                        seen.add(matched);
                        hits.add(new Hit(term, matched, i));
                        break;
                    }
                }
            }
        }
        hits.sort(Comparator.<Hit>comparingInt(h -> h.term().isHigh() ? 0 : 1).thenComparingInt(Hit::index));
        return hits;
    }

    public String languageName(String lang) {
        return languages.getOrDefault(lang, lang);
    }

    // ———— Normalisation (identique à profanity.py)

    /** Texte normalisé (minuscules, sans accents ni tashkeel) ; {@code index[k]} = position d'origine du caractère k. */
    private record Canon(String text, int[] index) {
    }

    private static Canon canonWithIndex(String text) {
        StringBuilder sb = new StringBuilder(text.length());
        List<Integer> index = new ArrayList<>(text.length());
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i) == '’' ? '\'' : text.charAt(i);
            StringBuilder piece = new StringBuilder();
            for (char lc : String.valueOf(c).toLowerCase(Locale.ROOT).toCharArray()) {
                String mapped = ARABIC.get(lc);
                piece.append(mapped != null ? mapped : String.valueOf(lc));
            }
            String normalized = Normalizer.normalize(piece, Normalizer.Form.NFD).replaceAll("\\p{Mn}", "");
            for (int k = 0; k < normalized.length(); k++) {
                sb.append(normalized.charAt(k));
                index.add(i);
            }
        }
        return new Canon(sb.toString(), index.stream().mapToInt(Integer::intValue).toArray());
    }

    static String canon(String text) {
        return canonWithIndex(text).text();
    }

    static List<String> tokens(String text) {
        return tokenize(text).stream().map(Tok::text).toList();
    }

    /** Mots normalisés avec leur position d'origine ; les lettres isolées consécutives (« p u t e ») sont recollées. */
    static List<Tok> tokenize(String text) {
        Canon canon = canonWithIndex(text);
        List<Tok> raw = new ArrayList<>();
        Matcher m = TOKEN.matcher(canon.text());
        while (m.find()) {
            raw.add(new Tok(m.group(), canon.index()[m.start()], canon.index()[m.end() - 1] + 1));
        }
        raw.add(null);
        List<Tok> merged = new ArrayList<>();
        List<Tok> singles = new ArrayList<>();
        for (Tok t : raw) {
            if (t != null && t.text().codePointCount(0, t.text().length()) == 1) {
                singles.add(t);
                continue;
            }
            if (singles.size() >= 3) {
                StringBuilder joined = new StringBuilder();
                singles.forEach(s -> joined.append(s.text()));
                merged.add(new Tok(joined.toString(), singles.get(0).start(), singles.get(singles.size() - 1).end()));
            } else {
                merged.addAll(singles);
            }
            singles.clear();
            if (t != null) {
                merged.add(t);
            }
        }
        List<Tok> out = new ArrayList<>();
        for (Tok t : merged) {
            // Ponctuation collée au mot (« connard! ») ; les mots faits seulement de symboles sont ignorés.
            String cleaned = strip(t.text(), "!");
            if (strip(cleaned, "*!").isEmpty()) {
                continue;
            }
            int start = t.start();
            int end = t.end();
            while (start < end && text.charAt(start) == '!') {
                start++;
            }
            while (end > start && text.charAt(end - 1) == '!') {
                end--;
            }
            out.add(new Tok(REPEATS.matcher(cleaned).replaceAll("$1"), start, end));
        }
        return out;
    }

    private static String leet(String token) {
        StringBuilder sb = new StringBuilder(token.length());
        for (char c : token.toCharArray()) {
            Character mapped = LEET.get(c);
            sb.append(mapped != null ? mapped : c);
        }
        return REPEATS.matcher(sb).replaceAll("$1");
    }

    private static boolean tokenMatches(String token, String word, boolean stem) {
        if (stem) {
            if (token.length() < word.length()) {
                return false;
            }
            token = token.substring(0, word.length());
        } else if (token.length() != word.length()) {
            return false;
        }
        for (int i = 0; i < word.length(); i++) {
            char t = token.charAt(i);
            if (t != word.charAt(i) && t != '*') {
                return false;
            }
        }
        return true;
    }

    /** Retire aux deux bouts les caractères de {@code chars} (comme {@code str.strip(chars)} en Python). */
    private static String strip(String s, String chars) {
        int start = 0;
        int end = s.length();
        while (start < end && chars.indexOf(s.charAt(start)) >= 0) {
            start++;
        }
        while (end > start && chars.indexOf(s.charAt(end - 1)) >= 0) {
            end--;
        }
        return s.substring(start, end);
    }

    private static String mask(String word, boolean keepShort) {
        int len = word.codePointCount(0, word.length());
        if (len <= 2) {
            return keepShort ? word : word.substring(0, word.offsetByCodePoints(0, 1)) + "*";
        }
        int firstEnd = word.offsetByCodePoints(0, 1);
        int lastStart = word.offsetByCodePoints(0, len - 1);
        return word.substring(0, firstEnd) + "*".repeat(len - 2) + word.substring(lastStart);
    }
}
