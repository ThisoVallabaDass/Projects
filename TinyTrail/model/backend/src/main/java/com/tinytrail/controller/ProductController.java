package com.tinytrail.controller;

import com.tinytrail.dto.ProductDto;
import com.tinytrail.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/products")
@Tag(name = "Products", description = "Product management endpoints")
public class ProductController {

    @Autowired
    private ProductService productService;

    @GetMapping("/search")
    @Operation(summary = "Search products by pincode", description = "Get products available in a specific pincode")
    public ResponseEntity<List<ProductDto>> searchProductsByPincode(@RequestParam String pincode) {
        List<ProductDto> products = productService.searchProductsByPincode(pincode);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/search/category")
    @Operation(summary = "Search products by pincode and category", description = "Get products by pincode and category")
    public ResponseEntity<List<ProductDto>> searchProductsByPincodeAndCategory(
            @RequestParam String pincode, @RequestParam String category) {
        List<ProductDto> products = productService.searchProductsByPincodeAndCategory(pincode, category);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/search/term")
    @Operation(summary = "Search products by term", description = "Search products by name or description")
    public ResponseEntity<List<ProductDto>> searchProducts(@RequestParam String q) {
        List<ProductDto> products = productService.searchProducts(q);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product by ID", description = "Get product details by ID")
    public ResponseEntity<ProductDto> getProductById(@PathVariable Long id) {
        try {
            ProductDto product = productService.getProductById(id);
            return ResponseEntity.ok(product);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping
    @Operation(summary = "Create product", description = "Create a new product (seller only)")
    public ResponseEntity<ProductDto> createProduct(
            Authentication authentication,
            @RequestParam String name,
            @RequestParam String description,
            @RequestParam String price,
            @RequestParam String pincode,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) MultipartFile image) {
        try {
            ProductDto product = productService.createProduct(
                authentication.getName(), name, description, price, pincode, category, image);
            return ResponseEntity.ok(product);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/seller")
    @Operation(summary = "Get seller products", description = "Get all products for current seller")
    public ResponseEntity<List<ProductDto>> getSellerProducts(Authentication authentication) {
        try {
            List<ProductDto> products = productService.getProductsBySeller(authentication.getName());
            return ResponseEntity.ok(products);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/categories")
    @Operation(summary = "Get product categories", description = "Get all available product categories")
    public ResponseEntity<List<String>> getCategories() {
        List<String> categories = productService.getCategories();
        return ResponseEntity.ok(categories);
    }
}
