package com.tinytrail.service;

import com.tinytrail.dto.ProductDto;
import com.tinytrail.entity.Product;
import com.tinytrail.entity.Seller;
import com.tinytrail.entity.User;
import com.tinytrail.repository.ProductRepository;
import com.tinytrail.repository.SellerRepository;
import com.tinytrail.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private SellerRepository sellerRepository;

    @Autowired
    private UserRepository userRepository;

    private static final String UPLOAD_DIR = "uploads/";

    public List<ProductDto> searchProductsByPincode(String pincode) {
        List<Product> products = productRepository.findByPincode(pincode);
        return products.stream().map(ProductDto::new).collect(Collectors.toList());
    }

    public List<ProductDto> searchProductsByPincodeAndCategory(String pincode, String category) {
        List<Product> products = productRepository.findByPincodeAndCategory(pincode, category);
        return products.stream().map(ProductDto::new).collect(Collectors.toList());
    }

    public List<ProductDto> searchProducts(String searchTerm) {
        List<Product> products = productRepository.searchByNameOrDescription(searchTerm);
        return products.stream().map(ProductDto::new).collect(Collectors.toList());
    }

    public ProductDto getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
        return new ProductDto(product);
    }

    public ProductDto createProduct(String username, String name, String description, 
                                  String price, String pincode, String category, MultipartFile image) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Seller seller = sellerRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("User is not a seller"));

        Product product = new Product();
        product.setSeller(seller);
        product.setName(name);
        product.setDescription(description);
        product.setPrice(new java.math.BigDecimal(price));
        product.setPincode(pincode);
        product.setCategory(category);

        if (image != null && !image.isEmpty()) {
            String imageUrl = saveImage(image);
            product.setImageUrl(imageUrl);
        }

        product = productRepository.save(product);
        return new ProductDto(product);
    }

    public List<ProductDto> getProductsBySeller(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Seller seller = sellerRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("User is not a seller"));

        List<Product> products = productRepository.findBySellerId(seller.getId());
        return products.stream().map(ProductDto::new).collect(Collectors.toList());
    }

    public List<String> getCategories() {
        return productRepository.findDistinctCategories();
    }

    private String saveImage(MultipartFile image) {
        try {
            // Create upload directory if it doesn't exist
            Path uploadPath = Paths.get(UPLOAD_DIR);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Generate unique filename
            String filename = System.currentTimeMillis() + "_" + image.getOriginalFilename();
            Path filePath = uploadPath.resolve(filename);

            // Save file
            Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Return relative URL
            return "/uploads/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Failed to save image", e);
        }
    }
}
