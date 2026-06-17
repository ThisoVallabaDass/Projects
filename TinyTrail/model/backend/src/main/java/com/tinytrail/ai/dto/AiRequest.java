package com.tinytrail.ai.dto;

import java.util.Map;

public class AiRequest {
    public String text;
    public String locale;
    public Map<String,Object> userLocation;
    public Map<String,Object> preferences;
}
