package com.tinytrail.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VendorController.class)
public class VendorControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Test
    public void getVendor() throws Exception {
        mockMvc.perform(get("/api/vendors/1")).andExpect(status().isOk());
    }
}
package com.tinytrail.controller;

import com.tinytrail.entity.Vendor;
import com.tinytrail.repository.SubscriptionPlanRepository;
import com.tinytrail.repository.SubscriptionRepository;
import com.tinytrail.repository.VendorRepository;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VendorController.class)
public class VendorControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private VendorRepository vendorRepository;

    @MockBean
    private SubscriptionPlanRepository planRepository;

    @MockBean
    private SubscriptionRepository subscriptionRepository;

    @Test
    public void getVendor_returns200() throws Exception {
        Vendor v = new Vendor();
        v.setId(1L);
        Mockito.when(vendorRepository.findById(anyLong())).thenReturn(Optional.of(v));

        mockMvc.perform(get("/api/vendors/1").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }
}
