package tn.lammapets.backend.store.insights;

import java.time.Duration;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.JsonValue;
import com.anthropic.errors.AnthropicException;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.StopReason;
import com.anthropic.models.messages.StructuredMessage;
import com.anthropic.models.messages.StructuredMessageCreateParams;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.insights.SalesDtos.SalesStats;

/** Commentaire des ventes par l'API Claude. La clé reste sur le serveur. */
class ClaudeSalesCommentator implements SalesCommentator {

	private static final Logger log = LoggerFactory.getLogger(ClaudeSalesCommentator.class);

	private static final String INSTRUCTIONS = """
			Tu aides l'administrateur d'une petite boutique en ligne d'accessoires et de nourriture pour animaux, en
			Tunisie. À partir des chiffres fournis, écris en français :
			- summary : deux ou trois phrases qui résument la période ;
			- points : de 2 à 4 actions concrètes et courtes (réapprovisionner, mettre en avant, surveiller les annulations…).

			Règles :
			- N'utilise que les chiffres fournis : n'en invente aucun et ne fais pas de calcul qui n'y figure pas.
			- Si les données sont trop faibles pour conclure (peu ou pas de commandes), dis-le simplement.
			- Les montants sont en dinars (DT). Reste factuel, sans formules d'enthousiasme.
			""";

	private final AnthropicClient client;

	private final String model;

	ClaudeSalesCommentator(String apiKey, String model) {
		this.client = AnthropicOkHttpClient.builder()
			.apiKey(apiKey)
			.timeout(Duration.ofSeconds(60))
			.maxRetries(1)
			.build();
		this.model = model;
	}

	@Override
	public Commentary comment(SalesStats stats) {
		StructuredMessageCreateParams<Commentary> params = MessageCreateParams.builder()
			.model(model)
			.maxTokens(8000L)
			.system(INSTRUCTIONS)
			// En cas de refus par les filtres de sécurité, l'API retente avec un autre modèle.
			.putAdditionalHeader("anthropic-beta", "server-side-fallback-2026-07-01")
			.putAdditionalBodyProperty("fallbacks", JsonValue.from("default"))
			.addUserMessage(SalesCommentator.describe(stats))
			.outputConfig(Commentary.class)
			.build();
		try {
			StructuredMessage<Commentary> response = client.messages().create(params);
			if (response.stopReason().filter(StopReason.REFUSAL::equals).isPresent()) {
				throw unavailable();
			}
			Commentary c = response.content()
				.stream()
				.flatMap(block -> block.text().stream())
				.findFirst()
				.map(text -> text.text())
				.orElseThrow(ClaudeSalesCommentator::unavailable);
			return new Commentary(c.summary(), c.points() == null ? List.of() : c.points());
		}
		catch (AnthropicException e) {
			log.error("Résumé des ventes : échec de l'appel au fournisseur : {}", e.getMessage());
			throw unavailable();
		}
	}

	private static ApiException unavailable() {
		return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "L'analyse par IA est indisponible pour le moment.");
	}

}
