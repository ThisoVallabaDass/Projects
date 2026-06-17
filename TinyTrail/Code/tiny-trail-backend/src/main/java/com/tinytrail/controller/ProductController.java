package com.tinytrail.controller;

import com.tinytrail.dto.ApiResponse;
import com.tinytrail.entity.Product;
import com.tinytrail.entity.User;
import com.tinytrail.service.ProductService;
import com.tinytrail.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/products")
public class ProductController {
    
    @Autowired
    private ProductService productService;
    
    @Autowired
    private UserService userService;
    
    // Public endpoints for browsing products
    @GetMapping("/public/search")
    public ResponseEntity<?> searchProducts(
            @RequestParam(required = false) String pincode,
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        
        try {
            Sort sort = sortDir.equalsIgnoreCase("desc") ? 
                Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
            Pageable pageable = PageRequest.of(page, size, sort);
            
            Page<Product> products;
            
            if (category != null && !category.isEmpty() && pincode != null && !pincode.isEmpty()) {
                products = productService.findProductsByCategory(category, pincode, pageable);
            } else if (query != null && !query.isEmpty()) {
                if (pincode != null && !pincode.isEmpty()) {
                    products = productService.searchProductsByPincode(pincode, query, pageable);
                } else {
                    products = productService.searchProducts(query, pageable);
                }
            } else if (pincode != null && !pincode.isEmpty()) {
                products = productService.findProductsByPincode(pincode, pageable);
            } else {
                products = Page.empty();
            }
            
            return ResponseEntity.ok(new ApiResponse(true, "Products retrieved successfully", products));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving products: " + e.getMessage()));
        }
    }
    
    @GetMapping("/public/categories")
    public ResponseEntity<?> getCategories(@RequestParam(required = false) String pincode) {
        try {
            List<String> categories;
            if (pincode != null && !pincode.isEmpty()) {
                categories = productService.getCategoriesByPincode(pincode);
            } else {
                categories = productService.getAllCategories();
            }
            return ResponseEntity.ok(new ApiResponse(true, "Categories retrieved successfully", categories));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving categories: " + e.getMessage()));
        }
    }
    
    @GetMapping("/public/{id}")
    public ResponseEntity<?> getProductById(@PathVariable Long id) {
        try {
            Optional<Product> product = productService.findById(id);
            if (product.isPresent()) {
                return ResponseEntity.ok(new ApiResponse(true, "Product retrieved successfully", product.get()));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving product: " + e.getMessage()));
        }
    }
    
    // Authenticated endpoints
    @PostMapping
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> createProduct(@Valid @RequestBody ProductRequest productRequest, 
                                         Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            
            Product product = new Product();
            product.setName(productRequest.getName());
            product.setDescription(productRequest.getDescription());
            product.setPrice(productRequest.getPrice());
            product.setCategory(productRequest.getCategory());
            product.setLanguage(productRequest.getLanguage());
            product.setEntrepreneur(entrepreneur);
            product.setPincode(productRequest.getPincode() != null ? productRequest.getPincode() : entrepreneur.getPincode());
            product.setImageUrl(productRequest.getImageUrl());
            product.setStockQuantity(productRequest.getStockQuantity());
            
            Product savedProduct = productService.createProduct(product);
            
            return ResponseEntity.ok(new ApiResponse(true, "Product created successfully", savedProduct));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error creating product: " + e.getMessage()));
        }
    }
    
    @GetMapping("/my-products")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> getMyProducts(Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            List<Product> products = productService.findProductsByEntrepreneur(entrepreneur);
            return ResponseEntity.ok(new ApiResponse(true, "Products retrieved successfully", products));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving products: " + e.getMessage()));
        }
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> updateProduct(@PathVariable Long id, 
                                         @Valid @RequestBody ProductRequest productRequest,
                                         Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            Optional<Product> productOpt = productService.findById(id);
            
            if (!productOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Product product = productOpt.get();
            
            // Check if the product belongs to the authenticated entrepreneur
            if (!product.getEntrepreneur().getId().equals(entrepreneur.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "You can only update your own products"));
            }
            
            product.setName(productRequest.getName());
            product.setDescription(productRequest.getDescription());
            product.setPrice(productRequest.getPrice());
            product.setCategory(productRequest.getCategory());
            product.setLanguage(productRequest.getLanguage());
            product.setPincode(productRequest.getPincode() != null ? productRequest.getPincode() : product.getPincode());
            product.setImageUrl(productRequest.getImageUrl());
            product.setStockQuantity(productRequest.getStockQuantity());
            
            Product updatedProduct = productService.updateProduct(product);
            
            return ResponseEntity.ok(new ApiResponse(true, "Product updated successfully", updatedProduct));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error updating product: " + e.getMessage()));
        }
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> deleteProduct(@PathVariable Long id, Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            Optional<Product> productOpt = productService.findById(id);
            
            if (!productOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Product product = productOpt.get();
            
            // Check if the product belongs to the authenticated entrepreneur
            if (!product.getEntrepreneur().getId().equals(entrepreneur.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "You can only delete your own products"));
            }
            
            productService.deleteProduct(id);
            
            return ResponseEntity.ok(new ApiResponse(true, "Product deleted successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error deleting product: " + e.getMessage()));
        }
    }
    
    @PutMapping("/{id}/toggle-availability")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> toggleProductAvailability(@PathVariable Long id, Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            Optional<Product> productOpt = productService.findById(id);
            
            if (!productOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Product product = productOpt.get();
            
            // Check if the product belongs to the authenticated entrepreneur
            if (!product.getEntrepreneur().getId().equals(entrepreneur.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "You can only modify your own products"));
            }
            
            Product updatedProduct = productService.toggleProductAvailability(id);
            
            return ResponseEntity.ok(new ApiResponse(true, "Product availability updated successfully", updatedProduct));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error updating product availability: " + e.getMessage()));
        }
    }
    
    // Inner class for product request
    public static class ProductRequest {
        private String name;
        private String description;
        private java.math.BigDecimal price;
        private String category;
        private Product.Language language = Product.Language.ENGLISH;
        private String pincode;
        private String imageUrl;
        private Integer stockQuantity;
        
        // Getters and setters
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        
        public java.math.BigDecimal getPrice() { return price; }
        public void setPrice(java.math.BigDecimal price) { this.price = price; }
        
        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }
        
        public Product.Language getLanguage() { return language; }
        public void setLanguage(Product.Language language) { this.language = language; }
        
        public String getPincode() { return pincode; }
        public void setPincode(String pincode) { this.pincode = pincode; }
        
        public String getImageUrl() { return imageUrl; }
        public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
        
        public Integer getStockQuantity() { return stockQuantity; }
        public void setStockQuantity(Integer stockQuantity) { this.stockQuantity = stockQuantity; }
    }
}
