package com.tinytrail.service.ai.dto;

import java.util.Map;

public class AiRequest {
    private String text;
    private String locale;
    private Map<String, Object> userLocation;
    private Map<String, Object> context;

    // getters and setters
    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
    public String getLocale() { return locale; }
    public void setLocale(String locale) { this.locale = locale; }
    public Map<String, Object> getUserLocation() { return userLocation; }
    public void setUserLocation(Map<String, Object> userLocation) { this.userLocation = userLocation; }
    public Map<String, Object> getContext() { return context; }
    public void setContext(Map<String, Object> context) { this.context = context; }
}
