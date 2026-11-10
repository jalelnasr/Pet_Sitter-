package com.petsitter.store;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import com.jayway.jsonpath.JsonPath;

/**
 * Parcours de la boutique sur base H2 en mémoire : catalogue, commande, stock, annulation, suivi par
 * l'administrateur, avis, photos et résumé des ventes. Les comptes de démonstration servent d'identité.
 */
@SpringBootTest(properties = {
		"petsitter.demo-data=true", // comptes de démonstration utilisés par le test
		"spring.jpa.hibernate.ddl-auto=create-drop",
		"spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
		"spring.datasource.url=jdbc:h2:mem:petsitter-store;DB_CLOSE_DELAY=-1;MODE=MySQL",
		"spring.datasource.driver-class-name=org.h2.Driver",
		"spring.datasource.username=sa",
		"spring.datasource.password=",
		"spring.jpa.show-sql=false",
		"petsitter.upload.dir=target/test-uploads",
		"petsitter.auth.allow-demo-header=true"
})
@AutoConfigureMockMvc
class StoreFlowTest {

	private static final String OWNER = "OWNER_DEMO";

	private static final String SITTER = "PETSITTER_DEMO";

	private static final String ADMIN = "ADMIN_DEMO";

	@Autowired
	private MockMvc mvc;

	private static MockHttpServletRequestBuilder as(MockHttpServletRequestBuilder b, String user) {
		return user == null ? b : b.header("X-Demo-User-Id", user);
	}

	private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder b, String user, String body) {
		return as(b, user).contentType(MediaType.APPLICATION_JSON).content(body);
	}

	/** Produit isolé : les tests de stock ne dépendent pas les uns des autres. */
	private Object[] newProduct(int price, int stock) throws Exception {
		String id = "p-" + UUID.randomUUID().toString().substring(0, 8);
		String res = mvc.perform(json(post("/api/admin/products"), ADMIN, """
				{"id":"%s","product":{"name":"Produit %s","brand":"Marque","category":"jouets","species":["chat"],
				 "description":"Desc","options":[{"label":"U","price":%d,"stock":%d}],"packKind":"object",
				 "color":"#0F5534","tint":"#E3F1E7","icon":"cat"}}""".formatted(id, id, price, stock)))
			.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
		int option = JsonPath.read(res, "$.options[0].id");
		return new Object[] { id, option };
	}

	private ResultActions order(String user, int option, int qty) throws Exception {
		return mvc.perform(json(post("/api/orders"), user, """
				{"items":[{"optionId":%d,"quantity":%d}],"payment":"CASH","recipient":"Test",
				 "phone":"+216 20 000 000","address":"Rue du Lac","city":"La Marsa"}""".formatted(option, qty)));
	}

	private void deliver(int orderId) throws Exception {
		for (String s : List.of("PREPARING", "SHIPPED", "DELIVERED")) {
			mvc.perform(json(patch("/api/admin/orders/" + orderId + "/status"), ADMIN, "{\"status\":\"" + s + "\"}"))
				.andExpect(status().isOk());
		}
	}

	@Test
	@DisplayName("Le catalogue de démonstration est public, filtrable et sans notes inventées")
	void catalogue() throws Exception {
		mvc.perform(get("/api/products").param("size", "100")).andExpect(status().isOk())
			.andExpect(jsonPath("$.totalItems").value(org.hamcrest.Matchers.greaterThanOrEqualTo(15)));
		mvc.perform(get("/api/products/croq-chat")).andExpect(status().isOk())
			.andExpect(jsonPath("$.options[0].price").value(49)).andExpect(jsonPath("$.reviews").value(0));
		mvc.perform(get("/api/products").param("species", "poisson").param("category", "accessoires"))
			.andExpect(jsonPath("$.items[0].id").value("aquarium"));
	}

	@Test
	@DisplayName("La gestion du catalogue et des commandes est réservée à l'administrateur")
	void adminOnly() throws Exception {
		mvc.perform(get("/api/admin/orders")).andExpect(status().isUnauthorized());
		mvc.perform(as(get("/api/admin/orders"), OWNER)).andExpect(status().isForbidden());
		mvc.perform(as(get("/api/admin/products"), SITTER)).andExpect(status().isForbidden());
		mvc.perform(as(get("/api/admin/sales-summary"), OWNER)).andExpect(status().isForbidden());
		mvc.perform(as(get("/api/admin/orders"), ADMIN)).andExpect(status().isOk());
		order(null, 1, 1).andExpect(status().isUnauthorized());
	}

	@Test
	@DisplayName("Le serveur calcule le total, retire le stock et refuse de survendre")
	void orderAndStock() throws Exception {
		int option = (int) newProduct(79, 3)[1];
		order(OWNER, option, 1).andExpect(status().isCreated()).andExpect(jsonPath("$.total").value(86))
			.andExpect(jsonPath("$.shipping").value(7)).andExpect(jsonPath("$.number")
				.value(org.hamcrest.Matchers.startsWith("PS-")));
		order(OWNER, option, 3).andExpect(status().isConflict())
			.andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Stock insuffisant")));
		order(OWNER, option, 2).andExpect(status().isCreated());
		order(OWNER, option, 1).andExpect(status().isConflict());
	}

	@Test
	@DisplayName("Un administrateur gère la boutique mais ne passe pas de commande")
	void adminCannotOrder() throws Exception {
		int option = (int) newProduct(10, 5)[1];
		order(ADMIN, option, 1).andExpect(status().isForbidden());
		order(SITTER, option, 1).andExpect(status().isCreated());
	}

	@Test
	@DisplayName("Annuler rend le stock, une seule fois ; chacun ne voit que ses commandes")
	void cancelAndPrivacy() throws Exception {
		int option = (int) newProduct(10, 1)[1];
		String res = order(OWNER, option, 1).andExpect(status().isCreated()).andReturn().getResponse()
			.getContentAsString();
		int id = JsonPath.read(res, "$.id");
		mvc.perform(as(get("/api/orders/" + id), SITTER)).andExpect(status().isNotFound());
		mvc.perform(as(post("/api/orders/" + id + "/cancel"), OWNER)).andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value("CANCELLED"));
		mvc.perform(as(post("/api/orders/" + id + "/cancel"), OWNER)).andExpect(status().isConflict());
		order(OWNER, option, 1).andExpect(status().isCreated());
	}

	@Test
	@DisplayName("Le suivi suit les étapes prévues et la livraison marque la commande payée")
	void statusFlow() throws Exception {
		String res = order(OWNER, (int) newProduct(10, 5)[1], 1).andReturn().getResponse().getContentAsString();
		int id = JsonPath.read(res, "$.id");
		mvc.perform(json(patch("/api/admin/orders/" + id + "/status"), ADMIN, "{\"status\":\"DELIVERED\"}"))
			.andExpect(status().isConflict());
		deliver(id);
		mvc.perform(as(get("/api/orders/" + id), OWNER)).andExpect(jsonPath("$.paymentStatus").value("PAID"))
			.andExpect(jsonPath("$.history.length()").value(4));
	}

	@Test
	@DisplayName("Seul un client qui a reçu le produit peut donner un avis")
	void reviews() throws Exception {
		Object[] p = newProduct(10, 5);
		String url = "/api/products/" + p[0] + "/reviews";
		String review = "{\"rating\":4,\"comment\":\"Très bien\"}";
		mvc.perform(json(put(url + "/me"), OWNER, review)).andExpect(status().isConflict());
		String res = order(OWNER, (int) p[1], 1).andReturn().getResponse().getContentAsString();
		deliver(JsonPath.read(res, "$.id"));
		mvc.perform(json(put(url + "/me"), OWNER, review)).andExpect(status().isOk())
			.andExpect(jsonPath("$.authorName").value("Amira"));
		mvc.perform(get(url)).andExpect(jsonPath("$.count").value(1)).andExpect(jsonPath("$.average").value(4.0));
		int reviewId = JsonPath.read(mvc.perform(get(url)).andReturn().getResponse().getContentAsString(),
				"$.items[0].id");
		mvc.perform(as(delete("/api/admin/reviews/" + reviewId), OWNER)).andExpect(status().isForbidden());
		mvc.perform(as(delete("/api/admin/reviews/" + reviewId), ADMIN)).andExpect(status().isNoContent());
		mvc.perform(get("/api/products/" + p[0])).andExpect(jsonPath("$.reviews").value(0));
	}

	@Test
	@DisplayName("L'administrateur envoie une photo ; seuls les vrais fichiers image sont acceptés")
	void photos() throws Exception {
		byte[] png = { (byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3 };
		String res = mvc.perform(multipart("/api/admin/product-images")
			.file(new MockMultipartFile("file", "../pirate.svg", "image/svg+xml", png)).header("X-Demo-User-Id", ADMIN))
			.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
		String url = JsonPath.read(res, "$.url");
		assertThat(url).startsWith("/uploads/products/").endsWith(".png").doesNotContain("pirate");
		mvc.perform(multipart("/api/admin/product-images")
			.file(new MockMultipartFile("file", "x.svg", "image/svg+xml", "<svg/>".getBytes()))
			.header("X-Demo-User-Id", ADMIN)).andExpect(status().isBadRequest());
		mvc.perform(multipart("/api/admin/product-images").file(new MockMultipartFile("file", "x.png", "image/png", png))
			.header("X-Demo-User-Id", OWNER)).andExpect(status().isForbidden());
	}

	@Test
	@DisplayName("Le résumé des ventes ne compte que les vraies ventes")
	void salesSummary() throws Exception {
		String before = mvc.perform(as(get("/api/admin/sales-summary"), ADMIN)).andExpect(status().isOk()).andReturn()
			.getResponse().getContentAsString();
		int revenue = JsonPath.read(before, "$.stats.revenue");
		int cancelled = JsonPath.read(before, "$.stats.cancelled");
		int option = (int) newProduct(40, 6)[1];
		order(OWNER, option, 2).andExpect(status().isCreated());
		String res = order(OWNER, option, 1).andReturn().getResponse().getContentAsString();
		mvc.perform(as(post("/api/orders/" + JsonPath.read(res, "$.id") + "/cancel"), OWNER));
		mvc.perform(as(get("/api/admin/sales-summary"), ADMIN)).andExpect(status().isOk())
			.andExpect(jsonPath("$.stats.revenue").value(revenue + 80))
			.andExpect(jsonPath("$.stats.cancelled").value(cancelled + 1))
			.andExpect(jsonPath("$.stats.lowStock[?(@.stock == 4)]").exists())
			.andExpect(jsonPath("$.commentary").isString());
		mvc.perform(as(get("/api/admin/sales-summary").param("days", "0"), ADMIN)).andExpect(status().isBadRequest());
	}

}
