package com.tinytrail.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Vendor entity representing a micro-vendor/seller with story and subscription features
 * TODO: Add geolocation coordinates (latitude, longitude) for map integration
 */
@Entity
@Table(name = "vendors")
public class Vendor {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @NotBlank
    @Size(max = 255)
    @Column(name = "shop_name")
    private String shopName;
    
    @Size(max = 255)
    private String tagline;
    
    @Size(max = 255)
    @Column(name = "avatar_url")
    private String avatarUrl;
    
    @NotBlank
    @Size(max = 10)
    private String pincode;
    
    @NotBlank
    @Size(max = 500)
    private String address;
    
    @Size(max = 2000)
    @Column(name = "story_text", columnDefinition = "TEXT")
    private String storyText;
    
    @Size(max = 255)
    @Column(name = "story_video_url")
    private String storyVideoUrl;
    
    @Size(max = 255)
    @Column(name = "handwritten_menu_url")
    private String handwrittenMenuUrl;
    
    @Column(name = "is_verified_home_kitchen")
    private Boolean isVerifiedHomeKitchen = false;
    
    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @OneToMany(mappedBy = "vendor", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Product> products = new ArrayList<>();
    
    @OneToMany(mappedBy = "vendor", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<SubscriptionPlan> subscriptionPlans = new ArrayList<>();
    
    @OneToMany(mappedBy = "vendor", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Subscription> subscriptions = new ArrayList<>();
    
    // Constructors
    public Vendor() {}
    
    public Vendor(User user, String shopName, String pincode, String address) {
        this.user = user;
        this.shopName = shopName;
        this.pincode = pincode;
        this.address = address;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public String getShopName() {
        return shopName;
    }
    
    public void setShopName(String shopName) {
        this.shopName = shopName;
    }
    
    public String getTagline() {
        return tagline;
    }
    
    public void setTagline(String tagline) {
        this.tagline = tagline;
    }
    
    public String getAvatarUrl() {
        return avatarUrl;
    }
    
    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    
    public String getPincode() {
        return pincode;
    }
    
    public void setPincode(String pincode) {
        this.pincode = pincode;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public String getStoryText() {
        return storyText;
    }
    
    public void setStoryText(String storyText) {
        this.storyText = storyText;
    }
    
    public String getStoryVideoUrl() {
        return storyVideoUrl;
    }
    
    public void setStoryVideoUrl(String storyVideoUrl) {
        this.storyVideoUrl = storyVideoUrl;
    }
    
    public String getHandwrittenMenuUrl() {
        return handwrittenMenuUrl;
    }
    
    public void setHandwrittenMenuUrl(String handwrittenMenuUrl) {
        this.handwrittenMenuUrl = handwrittenMenuUrl;
    }
    
    public Boolean getIsVerifiedHomeKitchen() {
        return isVerifiedHomeKitchen;
    }
    
    public void setIsVerifiedHomeKitchen(Boolean verifiedHomeKitchen) {
        isVerifiedHomeKitchen = verifiedHomeKitchen;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public List<Product> getProducts() {
        return products;
    }
    
    public void setProducts(List<Product> products) {
        this.products = products;
    }
    
    public List<SubscriptionPlan> getSubscriptionPlans() {
        return subscriptionPlans;
    }
    
    public void setSubscriptionPlans(List<SubscriptionPlan> subscriptionPlans) {
        this.subscriptionPlans = subscriptionPlans;
    }
    
    public List<Subscription> getSubscriptions() {
        return subscriptions;
    }
    
    public void setSubscriptions(List<Subscription> subscriptions) {
        this.subscriptions = subscriptions;
    }
}
