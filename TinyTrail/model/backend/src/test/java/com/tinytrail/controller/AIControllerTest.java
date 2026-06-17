package com.tinytrail.controller;

import com.tinytrail.ai.AiService;
import com.tinytrail.ai.dto.AiRequest;
import com.tinytrail.ai.dto.AiResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@WebMvcTest(AIController.class)
public class AIControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockBean
    AiService aiService;

    @Test
    public void testQuery() throws Exception {
        AiResponse mock = new AiResponse();
        mock.text = "ok";
        when(aiService.query(org.mockito.ArgumentMatchers.any(AiRequest.class))).thenReturn(mock);

        mockMvc.perform(post("/api/ai/query").contentType(APPLICATION_JSON).content("{\"text\":\"hi\"}"))
                .andExpect(status().isOk());
    }
}
package com.tinytrail.controller;

import com.tinytrail.service.ai.AiService;
import com.tinytrail.service.ai.dto.AiRequest;
import com.tinytrail.service.ai.dto.AiResponse;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AIController.class)
public class AIControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AiService aiService;

    @Test
    public void query_returns200() throws Exception {
        AiResponse resp = new AiResponse();
        resp.setText("ok");
        Mockito.when(aiService.query(any(AiRequest.class))).thenReturn(resp);

        mockMvc.perform(post("/api/ai/query").contentType(MediaType.APPLICATION_JSON).content("{\"text\":\"hello\"}"))
                .andExpect(status().isOk());
    }
}
