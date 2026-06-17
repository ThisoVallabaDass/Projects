package com.tinytrail.service.ai;

import com.tinytrail.entity.Product;
import com.tinytrail.repository.ProductRepository;
import com.tinytrail.repository.VendorRepository;
import com.tinytrail.service.ai.dto.AiRequest;
import com.tinytrail.service.ai.dto.AiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * ExternalAiService - for now acts as a local mock that can be wired to an external LLM using AI_API_KEY
 * TODO: Wire to OpenAI/Anthropic APIs using AI_API_KEY and perform proper prompt engineering
 */
@Service
public class ExternalAiService implements AiService {

    private final String apiKey;
    private final VendorRepository vendorRepository;
    private final ProductRepository productRepository;

    public ExternalAiService(@Value("${AI_API_KEY:}") String apiKey, VendorRepository vendorRepository, ProductRepository productRepository) {
        this.apiKey = apiKey;
        this.vendorRepository = vendorRepository;
        this.productRepository = productRepository;
    }

    @Override
    public AiResponse query(AiRequest request) {
        // Simple mock response for dev: if the text mentions 'murukku' return sample vendor suggestions and cartel draft
        AiResponse resp = new AiResponse();
        resp.setText("I can help! Here are some local suggestions.");
        resp.setIntent("search");

        String text = (request.getText() == null ? "" : request.getText().toLowerCase());
        if (text.contains("murukku") || text.contains("murukku")) {
            // find vendors by pincode if userLocation provided, else return any
            List<Map<String, Object>> vendorSuggestions = new ArrayList<>();
            List vendors = vendorRepository.findByPincode((String) Optional.ofNullable(request.getUserLocation()).map(m -> m.get("pincode")).orElse("600001"));
            int i = 0;
            for (Object v : vendors) {
                Map<String, Object> map = new HashMap<>();
                try {
                    com.tinytrail.entity.Vendor vendor = (com.tinytrail.entity.Vendor) v;
                    map.put("vendorId", vendor.getId());
                    map.put("score", 0.9 - i * 0.1);
                    vendorSuggestions.add(map);
                } catch (Exception ex) {
                    // ignore
                }
                i++;
                if (i >= 3) break;
            }
            resp.setVendorSuggestions(vendorSuggestions);

            // create a cart draft from sample products if available
            List<Map<String, Object>> cartDraft = new ArrayList<>();
            List<Product> products = productRepository.findByPincode((String) Optional.ofNullable(request.getUserLocation()).map(m -> m.get("pincode")).orElse("600001"));
            int k = 0;
            for (Product p : products) {
                Map<String, Object> item = new HashMap<>();
                item.put("productId", p.getId());
                item.put("quantity", 1);
                cartDraft.add(item);
                k++;
                if (k >= 2) break;
            }
            resp.setCartDraft(cartDraft);

            List<Map<String, Object>> actions = new ArrayList<>();
            Map<String, Object> addAction = new HashMap<>();
            addAction.put("type", "add_to_cart");
            addAction.put("label", "Add suggested items");
            addAction.put("payload", Map.of("items", cartDraft));
            actions.add(addAction);
            resp.setUiActions(actions);
            resp.setText("I found some murukku near you — would you like to add them to your cart?");
            resp.setIntent("order");
        }

        // If no apiKey present, leave as mock. If apiKey present, TODO: call external API.
        if (this.apiKey != null && !this.apiKey.isBlank()) {
            // TODO: Call OpenAI/Anthropic or other LLM here and return structured response
        }

        return resp;
    }
}
