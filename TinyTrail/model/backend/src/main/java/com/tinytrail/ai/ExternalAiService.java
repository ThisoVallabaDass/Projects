package com.tinytrail.ai;

import com.tinytrail.ai.dto.AiRequest;
import com.tinytrail.ai.dto.AiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ExternalAiService implements AiService {

    @Value("${AI_API_KEY:}")
    private String aiApiKey;

    @Override
    public AiResponse query(AiRequest request) {
        // TODO: Replace mock with real LLM HTTP request using aiApiKey
        AiResponse r = new AiResponse();
        r.intent = "search";
        r.text = "This is a mock AI response. Wire ExternalAiService to a real provider using AI_API_KEY.";
        r.vendorSuggestions = new ArrayList<>();
        Map<String,Object> v = new HashMap<>();
        v.put("vendorId", 1);
        v.put("score", 0.9);
        r.vendorSuggestions.add(v);
        r.cartDraft = new ArrayList<>();
        Map<String,Object> c = new HashMap<>();
        c.put("productId", 101);
        c.put("quantity", 2);
        r.cartDraft.add(c);
        r.uiActions = new ArrayList<>();
        Map<String,Object> a = new HashMap<>();
        a.put("type","add_to_cart");
        a.put("label","Add suggested items");
        r.uiActions.add(a);
        return r;
    }
}
