package com.tinytrail.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
public class Product {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", nullable = false)
    private Seller seller;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendor_id")
    private Vendor vendor;
    
    @NotBlank
    @Size(max = 255)
    private String name;
    
    @NotBlank
    @Size(max = 1000)
    private String description;
    
    @DecimalMin(value = "0.0", inclusive = false)
    @Column(precision = 10, scale = 2)
    private BigDecimal price;
    
    @NotBlank
    @Size(max = 10)
    private String pincode;
    
    @Size(max = 255)
    @Column(name = "image_url")
    private String imageUrl;
    
    @Size(max = 100)
    private String category;
    
    @Column(name = "custom_options_schema", columnDefinition = "JSON")
    private String customOptionsSchema;
    
    @Column(name = "is_subscription_item")
    private Boolean isSubscriptionItem = false;
    
    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    // Constructors
    public Product() {}
    
    public Product(Seller seller, String name, String description, BigDecimal price, String pincode) {
        this.seller = seller;
        this.name = name;
        this.description = description;
        this.price = price;
        this.pincode = pincode;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Seller getSeller() {
        return seller;
    }
    
    public void setSeller(Seller seller) {
        this.seller = seller;
    }
    
    public Vendor getVendor() {
        return vendor;
    }
    
    public void setVendor(Vendor vendor) {
        this.vendor = vendor;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public BigDecimal getPrice() {
        return price;
    }
    
    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    
    public String getPincode() {
        return pincode;
    }
    
    public void setPincode(String pincode) {
        this.pincode = pincode;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public String getCategory() {
        return category;
    }
    
    public String getCustomOptionsSchema() {
        return customOptionsSchema;
    }
    
    public void setCustomOptionsSchema(String customOptionsSchema) {
        this.customOptionsSchema = customOptionsSchema;
    }
    
    public Boolean getIsSubscriptionItem() {
        return isSubscriptionItem;
    }
    
    public void setIsSubscriptionItem(Boolean subscriptionItem) {
        isSubscriptionItem = subscriptionItem;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
