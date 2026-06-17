package com.tinytrail.controller;

import com.tinytrail.entity.CollaborativeCart;
import com.tinytrail.service.collab.CollaborativeCartService;
import com.tinytrail.repository.CollaborativeCartRepository;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CollaborativeCartController.class)
public class CollaborativeCartControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CollaborativeCartRepository cartRepository;

    @MockBean
    private CollaborativeCartService cartService;

    @Test
    public void createCart_returns201() throws Exception {
        Mockito.when(cartService.generateCode()).thenReturn("ABCD");
        Mockito.when(cartRepository.save(any(CollaborativeCart.class))).thenAnswer(i -> i.getArguments()[0]);

        mockMvc.perform(post("/api/carts/create").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated());
    }

    @Test
    public void joinCart_notFound() throws Exception {
        Mockito.when(cartRepository.findByCartCode(anyString())).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/carts/join").contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"NOPE\"}"))
                .andExpect(status().isNotFound());
    }
}
