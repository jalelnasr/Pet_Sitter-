package com.petsitter.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class AdoptionUploadConfig implements WebMvcConfigurer {

    private static final Logger log = LoggerFactory.getLogger(AdoptionUploadConfig.class);

    @Value("${petsitter.upload.dir:uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path root = Paths.get(uploadDir).toAbsolutePath().normalize();
        String location = root.toUri().toString();
        if (!location.endsWith("/")) {
            location = location + "/";
        }
        log.info("Serving uploaded adoption images from {}", location);
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(location);
    }
}