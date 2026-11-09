package com.petsitter.store;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

import com.petsitter.store.product.ProductRepository;

/** Catalogue de démonstration de la boutique, inséré seulement quand la table des produits est vide. */
@Component
public class StoreDataInitializer implements ApplicationRunner {

	private static final Logger log = LoggerFactory.getLogger(StoreDataInitializer.class);

	private final ProductRepository products;

	private final DataSource dataSource;

	public StoreDataInitializer(ProductRepository products, DataSource dataSource) {
		this.products = products;
		this.dataSource = dataSource;
	}

	@Override
	public void run(ApplicationArguments args) {
		if (products.count() > 0) {
			return;
		}
		// Les données de démonstration ne doivent jamais empêcher l'application (ni les autres modules) de démarrer.
		// Tout ou rien : un catalogue à moitié inséré serait pire qu'un catalogue vide.
		try (Connection connection = dataSource.getConnection()) {
			boolean autoCommit = connection.getAutoCommit();
			connection.setAutoCommit(false);
			try {
				ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
						new ClassPathResource("store/demo-catalogue.sql"));
				populator.setSqlScriptEncoding("UTF-8");
				populator.populate(connection);
				connection.commit();
				log.info("Boutique : catalogue de démonstration inséré ({} produits)", products.count());
			}
			catch (RuntimeException e) {
				connection.rollback();
				log.warn("Boutique : catalogue de démonstration non inséré : {}", e.getMessage());
			}
			finally {
				connection.setAutoCommit(autoCommit);
			}
		}
		catch (SQLException e) {
			log.warn("Boutique : catalogue de démonstration non inséré : {}", e.getMessage());
		}
	}

}
