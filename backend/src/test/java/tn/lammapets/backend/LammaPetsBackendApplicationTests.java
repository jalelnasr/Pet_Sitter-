package tn.lammapets.backend;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import com.jayway.jsonpath.JsonPath;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LammaPetsBackendApplicationTests {

	@Autowired
	MockMvc mvc;

	private String register(String role) throws Exception {
		String body = "{\"name\":\"Test\",\"email\":\"%s@test.tn\",\"password\":\"motdepasse1\",\"role\":\"%s\"}"
			.formatted(UUID.randomUUID(), role);
		String res = mvc.perform(json(post("/api/auth/register"), null, body)).andExpect(status().isCreated())
			.andReturn().getResponse().getContentAsString();
		return JsonPath.read(res, "$.token");
	}

	private String admin() throws Exception {
		String res = mvc.perform(json(post("/api/auth/login"), null,
				"{\"email\":\"admin@test.tn\",\"password\":\"admin12345\"}"))
			.andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
		return JsonPath.read(res, "$.token");
	}

	private MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder b, String token, String body) {
		b.contentType(MediaType.APPLICATION_JSON).content(body);
		return token == null ? b : auth(b, token);
	}

	private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
		return b.header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
	}

	private String orderBody(int optionId, int qty, String payment) {
		return """
				{"items":[{"optionId":%d,"quantity":%d}],"payment":"%s","recipient":"Test",
				 "phone":"+216 20 000 000","address":"Rue du Lac Biwa","city":"La Marsa"}"""
			.formatted(optionId, qty, payment);
	}

	/** Crée un produit isolé pour que les tests de stock ne dépendent pas les uns des autres. */
	private int newProduct(int price, int stock) throws Exception {
		String id = "p-" + UUID.randomUUID().toString().substring(0, 8);
		String res = mvc.perform(json(post("/api/admin/products"), admin(), """
				{"id":"%s","product":{"name":"Produit","brand":"Marque","category":"jouets","species":["chat"],
				 "description":"Desc","options":[{"label":"U","price":%d,"stock":%d}],"packKind":"object",
				 "color":"#0F5534","tint":"#E3F1E7","icon":"cat"}}""".formatted(id, price, stock)))
			.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
		return JsonPath.read(res, "$.options[0].id");
	}

	private ResultActions order(String token, int optionId, int qty) throws Exception {
		return mvc.perform(json(post("/api/orders"), token, orderBody(optionId, qty, "CASH")));
	}

	@Test
	void catalogueIsPublicAndFilterable() throws Exception {
		mvc.perform(get("/api/products").param("size", "100")).andExpect(status().isOk())
			.andExpect(jsonPath("$.totalItems").value(greaterThanOrEqualTo(15)));
		mvc.perform(get("/api/products/croq-chat")).andExpect(status().isOk())
			.andExpect(jsonPath("$.options.length()").value(3))
			.andExpect(jsonPath("$.options[0].price").value(49))
			.andExpect(jsonPath("$.details[0].label").value("Composition"));
		mvc.perform(get("/api/products").param("species", "poisson").param("category", "accessoires"))
			.andExpect(jsonPath("$.items[0].id").value("aquarium"));
		mvc.perform(get("/api/products").param("q", "FÉLIN+")).andExpect(jsonPath("$.totalItems").value(2));
		mvc.perform(get("/api/products").param("category", "inconnu")).andExpect(status().isBadRequest());
	}

	@Test
	void adminRoutesAreProtectedForEveryOtherRole() throws Exception {
		mvc.perform(get("/api/admin/orders")).andExpect(status().isUnauthorized());
		mvc.perform(auth(get("/api/admin/orders"), register("OWNER"))).andExpect(status().isForbidden());
		mvc.perform(auth(get("/api/admin/products"), register("PETSITTER"))).andExpect(status().isForbidden());
		mvc.perform(auth(get("/api/admin/orders"), admin())).andExpect(status().isOk());
		mvc.perform(post("/api/orders")).andExpect(status().isUnauthorized());
	}

	@Test
	void nobodyCanRegisterAsAdmin() throws Exception {
		mvc.perform(json(post("/api/auth/register"), null,
				"{\"name\":\"X\",\"email\":\"x@test.tn\",\"password\":\"motdepasse1\",\"role\":\"ADMIN\"}"))
			.andExpect(status().isBadRequest());
	}

	@Test
	void duplicateEmailAndBadPasswordAreRejected() throws Exception {
		String body = "{\"name\":\"D\",\"email\":\"Dup@Test.tn\",\"password\":\"motdepasse1\",\"role\":\"OWNER\"}";
		mvc.perform(json(post("/api/auth/register"), null, body)).andExpect(status().isCreated());
		mvc.perform(json(post("/api/auth/register"), null, body.replace("Dup@Test.tn", "dup@test.tn")))
			.andExpect(status().isConflict());
		mvc.perform(json(post("/api/auth/login"), null, "{\"email\":\"dup@test.tn\",\"password\":\"mauvais-mdp\"}"))
			.andExpect(status().isUnauthorized());
	}

	@Test
	void serverComputesTotalsAndShippingRule() throws Exception {
		String user = register("OWNER");
		order(user, newProduct(79, 10), 1).andExpect(status().isCreated())
			.andExpect(jsonPath("$.subtotal").value(79)).andExpect(jsonPath("$.shipping").value(7))
			.andExpect(jsonPath("$.total").value(86)).andExpect(jsonPath("$.status").value("CONFIRMED"))
			.andExpect(jsonPath("$.number").value(startsWith("PS-")));
		order(user, newProduct(80, 10), 1).andExpect(jsonPath("$.shipping").value(0))
			.andExpect(jsonPath("$.total").value(80));
	}

	@Test
	void stockCannotGoNegative() throws Exception {
		int option = newProduct(10, 3);
		String user = register("OWNER");
		order(user, option, 4).andExpect(status().isConflict());
		order(user, option, 3).andExpect(status().isCreated());
		order(user, option, 1).andExpect(status().isConflict());
	}

	@Test
	void multiLineOrderRollsBackStockWhenOneLineFails() throws Exception {
		int ok = newProduct(10, 5);
		int low = newProduct(10, 1);
		String user = register("OWNER");
		String body = """
				{"items":[{"optionId":%d,"quantity":5},{"optionId":%d,"quantity":2}],"payment":"CASH","recipient":"T",
				 "phone":"20000000","address":"A","city":"C"}""".formatted(ok, low);
		mvc.perform(json(post("/api/orders"), user, body)).andExpect(status().isConflict());
		order(user, ok, 5).andExpect(status().isCreated());
	}

	@Test
	void concurrentOrdersNeverOversell() throws Exception {
		int option = newProduct(10, 5);
		String user = register("OWNER");
		ExecutorService pool = Executors.newFixedThreadPool(8);
		List<Callable<Integer>> tasks = new ArrayList<>();
		for (int i = 0; i < 20; i++) {
			tasks.add(() -> order(user, option, 1).andReturn().getResponse().getStatus());
		}
		int created = 0;
		for (Future<Integer> f : pool.invokeAll(tasks)) {
			created += f.get() == 201 ? 1 : 0;
		}
		pool.shutdown();
		assertThat(created).isEqualTo(5);
	}

	@Test
	void cancellingRestoresStockOnce() throws Exception {
		int option = newProduct(10, 1);
		String user = register("OWNER");
		String res = order(user, option, 1).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
		int id = JsonPath.read(res, "$.id");
		order(user, option, 1).andExpect(status().isConflict());
		mvc.perform(auth(post("/api/orders/" + id + "/cancel"), user)).andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value("CANCELLED")).andExpect(jsonPath("$.history.length()").value(2));
		mvc.perform(auth(post("/api/orders/" + id + "/cancel"), user)).andExpect(status().isConflict());
		order(user, option, 1).andExpect(status().isCreated());
		order(user, option, 1).andExpect(status().isConflict());
	}

	@Test
	void statusFollowsAllowedTransitionsAndDeliveryMarksPaid() throws Exception {
		String user = register("OWNER");
		String res = order(user, newProduct(10, 5), 1).andReturn().getResponse().getContentAsString();
		int id = JsonPath.read(res, "$.id");
		String admin = admin();
		String url = "/api/admin/orders/" + id + "/status";
		mvc.perform(json(patch(url), admin, "{\"status\":\"DELIVERED\"}")).andExpect(status().isConflict());
		mvc.perform(json(patch(url), admin, "{\"status\":\"PREPARING\"}")).andExpect(status().isOk());
		mvc.perform(auth(post("/api/orders/" + id + "/cancel"), user)).andExpect(status().isConflict());
		mvc.perform(json(patch(url), admin, "{\"status\":\"SHIPPED\"}")).andExpect(status().isOk());
		mvc.perform(json(patch(url), admin, "{\"status\":\"DELIVERED\"}")).andExpect(status().isOk())
			.andExpect(jsonPath("$.paymentStatus").value("PAID")).andExpect(jsonPath("$.history.length()").value(4));
	}

	@Test
	void customersOnlySeeTheirOwnOrders() throws Exception {
		String owner = register("OWNER");
		String sitter = register("PETSITTER");
		String res = order(owner, newProduct(10, 5), 1).andReturn().getResponse().getContentAsString();
		int id = JsonPath.read(res, "$.id");
		mvc.perform(auth(get("/api/orders/" + id), sitter)).andExpect(status().isNotFound());
		mvc.perform(auth(post("/api/orders/" + id + "/cancel"), sitter)).andExpect(status().isNotFound());
		mvc.perform(auth(get("/api/orders/" + id), owner)).andExpect(status().isOk());
		mvc.perform(auth(get("/api/orders/" + id), admin())).andExpect(status().isOk());
		mvc.perform(auth(get("/api/orders/me"), sitter)).andExpect(jsonPath("$.totalItems").value(0));
		mvc.perform(auth(get("/api/orders/me"), owner)).andExpect(jsonPath("$.items[0].id").value(id));
	}

	@Test
	void cardPaymentIsRefusedUntilAGatewayExists() throws Exception {
		mvc.perform(json(post("/api/orders"), register("OWNER"), orderBody(newProduct(10, 5), 1, "CARD")))
			.andExpect(status().isBadRequest());
	}

	@Test
	void deactivatedProductDisappearsAndCannotBeOrdered() throws Exception {
		String id = "retire-" + UUID.randomUUID().toString().substring(0, 8);
		String res = mvc.perform(json(post("/api/admin/products"), admin(), """
				{"id":"%s","product":{"name":"Retiré","brand":"M","category":"jouets","species":["chat"],
				 "description":"D","options":[{"label":"U","price":10,"stock":5}],"packKind":"object",
				 "color":"#0F5534","tint":"#E3F1E7","icon":"cat"}}""".formatted(id)))
			.andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
		int option = JsonPath.read(res, "$.options[0].id");
		mvc.perform(auth(delete("/api/admin/products/" + id), admin())).andExpect(status().isNoContent());
		mvc.perform(get("/api/products/" + id)).andExpect(status().isNotFound());
		order(register("OWNER"), option, 1).andExpect(status().isConflict());
	}

}
