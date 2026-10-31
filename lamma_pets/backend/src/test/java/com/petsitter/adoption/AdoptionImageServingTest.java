package com.petsitter.adoption;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:imgtest;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "petsitter.upload.dir=target/test-uploads"
})
@AutoConfigureMockMvc
class AdoptionImageServingTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void uploadedImageIsServed() throws Exception {
        byte[] png = Base64.getDecoder().decode(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=");

        MvcResult upload = mockMvc.perform(multipart("/api/adoption-listings/images")
                        .file(new MockMultipartFile("file", "test.png", "image/png", png))
                        .header("X-Demo-User-Id", "OWNER_DEMO"))
                .andExpect(status().isOk())
                .andReturn();

        String body = upload.getResponse().getContentAsString();
        String url = body.replaceAll(".*\"url\"\\s*:\\s*\"([^\"]+)\".*", "$1");

        mockMvc.perform(get(url))
                .andExpect(status().isOk());
    }
}
