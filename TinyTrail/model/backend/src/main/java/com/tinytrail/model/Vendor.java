package com.tinytrail.model;

import javax.persistence.*;
import java.util.List;

@Entity
@Table(name = "vendor")
public class Vendor {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String tagline;

    @Column(columnDefinition = "TEXT")
    private String storyText;

    private String storyVideoUrl;
    private String handwrittenMenuUrl;

    private boolean isVerifiedHomeKitchen = false;

    // TODO: add relationships to Product and SubscriptionPlan

    public Vendor() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getTagline() { return tagline; }
    public void setTagline(String tagline) { this.tagline = tagline; }
    public String getStoryText() { return storyText; }
    public void setStoryText(String storyText) { this.storyText = storyText; }
    public String getStoryVideoUrl() { return storyVideoUrl; }
    public void setStoryVideoUrl(String storyVideoUrl) { this.storyVideoUrl = storyVideoUrl; }
    public String getHandwrittenMenuUrl() { return handwrittenMenuUrl; }
    public void setHandwrittenMenuUrl(String handwrittenMenuUrl) { this.handwrittenMenuUrl = handwrittenMenuUrl; }
    public boolean isVerifiedHomeKitchen() { return isVerifiedHomeKitchen; }
    public void setVerifiedHomeKitchen(boolean verifiedHomeKitchen) { isVerifiedHomeKitchen = verifiedHomeKitchen; }
}
