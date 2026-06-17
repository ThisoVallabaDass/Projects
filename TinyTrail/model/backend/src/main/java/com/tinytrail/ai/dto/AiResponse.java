package com.tinytrail.ai.dto;

import java.util.List;
import java.util.Map;

public class AiResponse {
    public String intent;
    public String text;
    public List<Map<String,Object>> vendorSuggestions;
    public List<Map<String,Object>> cartDraft;
    public List<Map<String,Object>> uiActions;
}
