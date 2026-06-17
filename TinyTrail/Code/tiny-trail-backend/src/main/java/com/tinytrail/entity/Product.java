package com.tinytrail.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
public class Product {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Product name is required")
    @Size(max = 200)
    @Column(nullable = false)
    private String name;
    
    @Size(max = 1000)
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    
    @NotBlank(message = "Category is required")
    @Size(max = 100)
    @Column(nullable = false)
    private String category;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Language language = Language.ENGLISH;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "entrepreneur_id", nullable = false)
    private User entrepreneur;
    
    @NotBlank(message = "Pincode is required")
    @Size(min = 6, max = 6, message = "Pincode must be 6 digits")
    @Column(nullable = false)
    private String pincode;
    
    @Column(name = "image_url")
    private String imageUrl;
    
    @Column(name = "stock_quantity")
    private Integer stockQuantity = 0;
    
    @Column(name = "is_available")
    private Boolean isAvailable = true;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Constructors
    public Product() {}
    
    public Product(String name, String description, BigDecimal price, String category, 
                   Language language, User entrepreneur, String pincode) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.category = category;
        this.language = language;
        this.entrepreneur = entrepreneur;
        this.pincode = pincode;
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
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
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public Language getLanguage() {
        return language;
    }
    
    public void setLanguage(Language language) {
        this.language = language;
    }
    
    public User getEntrepreneur() {
        return entrepreneur;
    }
    
    public void setEntrepreneur(User entrepreneur) {
        this.entrepreneur = entrepreneur;
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
    
    public Integer getStockQuantity() {
        return stockQuantity;
    }
    
    public void setStockQuantity(Integer stockQuantity) {
        this.stockQuantity = stockQuantity;
    }
    
    public Boolean getIsAvailable() {
        return isAvailable;
    }
    
    public void setIsAvailable(Boolean isAvailable) {
        this.isAvailable = isAvailable;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public enum Language {
        ENGLISH, TAMIL
    }
}
