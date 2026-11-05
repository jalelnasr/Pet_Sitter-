package com.petsitter.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class PythonAiClientConfig {

    @Bean
    RestClient pythonAiRestClient(
            @Value("${petsitter.ai.python-url}") String pythonUrl,
            @Value("${petsitter.ai.connect-timeout-ms}") int connectTimeoutMs,
            @Value("${petsitter.ai.read-timeout-ms}") int readTimeoutMs) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutMs);
        factory.setReadTimeout(readTimeoutMs);
        return RestClient.builder()
                .baseUrl(pythonUrl)
                .requestFactory(factory)
                .build();
    }
}
