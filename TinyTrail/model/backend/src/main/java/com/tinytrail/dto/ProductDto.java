package com.tinytrail.dto;

import com.tinytrail.entity.Product;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public class ProductDto {
    
    private Long id;
    
    @NotBlank
    @Size(max = 255)
    private String name;
    
    @NotBlank
    @Size(max = 1000)
    private String description;
    
    @DecimalMin(value = "0.0", inclusive = false)
    private BigDecimal price;
    
    @NotBlank
    @Size(max = 10)
    private String pincode;
    
    private String imageUrl;
    
    private String category;
    
    private Long sellerId;
    
    private String sellerName;
    
    private String createdAt;
    
    // Constructors
    public ProductDto() {}
    
    public ProductDto(Product product) {
        this.id = product.getId();
        this.name = product.getName();
        this.description = product.getDescription();
        this.price = product.getPrice();
        this.pincode = product.getPincode();
        this.imageUrl = product.getImageUrl();
        this.category = product.getCategory();
        this.sellerId = product.getSeller().getId();
        this.sellerName = product.getSeller().getShopName();
        this.createdAt = product.getCreatedAt() != null ? product.getCreatedAt().toString() : null;
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
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public Long getSellerId() {
        return sellerId;
    }
    
    public void setSellerId(Long sellerId) {
        this.sellerId = sellerId;
    }
    
    public String getSellerName() {
        return sellerName;
    }
    
    public void setSellerName(String sellerName) {
        this.sellerName = sellerName;
    }
    
    public String getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
