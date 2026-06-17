package com.tinytrail.service.ai;

import com.tinytrail.service.ai.dto.AiRequest;
import com.tinytrail.service.ai.dto.AiResponse;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * MockAiService used when no external AI key is configured. Deterministic responses for local dev & tests.
 */
@Service
@Primary
public class MockAiService implements AiService {

    @Override
    public AiResponse query(AiRequest request) {
        AiResponse resp = new AiResponse();
        String text = request.getText() == null ? "" : request.getText().toLowerCase();
        if (text.contains("murukku") || text.contains("முறுக்கு")) {
            resp.setIntent("order");
            resp.setText("Found local murukku sellers. Suggesting items to add to cart.");
            List<Map<String,Object>> ui = new ArrayList<>();
            Map<String,Object> a = new HashMap<>();
            a.put("type","add_to_cart");
            a.put("label","Add suggested items");
            ui.add(a);
            resp.setUiActions(ui);
            List<Map<String,Object>> draft = new ArrayList<>();
            Map<String,Object> it = new HashMap<>();
            it.put("productId", 1);
            it.put("quantity", 2);
            draft.add(it);
            resp.setCartDraft(draft);
        } else {
            resp.setIntent("info");
            resp.setText("Hello! I can help find vendors, suggest items, or create a cart. Try saying 'murukku near me'.");
        }
        return resp;
    }
}
