package tn.lammapets.backend.config;

import java.nio.file.Path;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import tn.lammapets.backend.store.product.ProductImageService;

/** Sert les photos des produits depuis le dossier d'envoi. */
@Configuration
public class ImagesConfig implements WebMvcConfigurer {

	private final String directory;

	public ImagesConfig(@Value("${app.uploads.dir}") String directory) {
		this.directory = directory;
	}

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		String location = Path.of(directory).toAbsolutePath().toUri().toString();
		registry.addResourceHandler(ProductImageService.PUBLIC_PATH + "**")
			.addResourceLocations(location.endsWith("/") ? location : location + "/");
	}

}
