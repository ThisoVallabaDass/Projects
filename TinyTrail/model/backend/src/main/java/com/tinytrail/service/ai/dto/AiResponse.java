package com.tinytrail.service.ai.dto;

import java.util.List;
import java.util.Map;

public class AiResponse {
    private String intent;
    private String text;
    private List<Map<String, Object>> vendorSuggestions;
    private List<Map<String, Object>> cartDraft;
    private List<Map<String, Object>> uiActions;

    // getters and setters
    public String getIntent() { return intent; }
    public void setIntent(String intent) { this.intent = intent; }
    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
    public List<Map<String, Object>> getVendorSuggestions() { return vendorSuggestions; }
    public void setVendorSuggestions(List<Map<String, Object>> vendorSuggestions) { this.vendorSuggestions = vendorSuggestions; }
    public List<Map<String, Object>> getCartDraft() { return cartDraft; }
    public void setCartDraft(List<Map<String, Object>> cartDraft) { this.cartDraft = cartDraft; }
    public List<Map<String, Object>> getUiActions() { return uiActions; }
    public void setUiActions(List<Map<String, Object>> uiActions) { this.uiActions = uiActions; }
}
