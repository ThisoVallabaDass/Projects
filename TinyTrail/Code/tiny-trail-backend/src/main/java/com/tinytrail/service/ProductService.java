package com.tinytrail.service;

import com.tinytrail.entity.Product;
import com.tinytrail.entity.User;
import com.tinytrail.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ProductService {
    
    @Autowired
    private ProductRepository productRepository;
    
    public Product createProduct(Product product) {
        return productRepository.save(product);
    }
    
    public Optional<Product> findById(Long id) {
        return productRepository.findById(id);
    }
    
    public List<Product> findAllProducts() {
        return productRepository.findAll();
    }
    
    public List<Product> findProductsByEntrepreneur(User entrepreneur) {
        return productRepository.findByEntrepreneur(entrepreneur);
    }
    
    public List<Product> findActiveProductsByEntrepreneur(Long entrepreneurId) {
        return productRepository.findActiveProductsByEntrepreneur(entrepreneurId);
    }
    
    public Page<Product> findProductsByPincode(String pincode, Pageable pageable) {
        return productRepository.findByPincodeAndIsAvailable(pincode, true, pageable);
    }
    
    public Page<Product> findProductsByCategory(String category, String pincode, Pageable pageable) {
        return productRepository.findByCategoryAndPincodeAndIsAvailable(category, pincode, true, pageable);
    }
    
    public Page<Product> searchProducts(String searchTerm, Pageable pageable) {
        return productRepository.searchProducts(searchTerm, pageable);
    }
    
    public Page<Product> searchProductsByPincode(String pincode, String searchTerm, Pageable pageable) {
        return productRepository.searchProductsByPincode(pincode, searchTerm, pageable);
    }
    
    public List<String> getAllCategories() {
        return productRepository.findAllCategories();
    }
    
    public List<String> getCategoriesByPincode(String pincode) {
        return productRepository.findCategoriesByPincode(pincode);
    }
    
    public Product updateProduct(Product product) {
        return productRepository.save(product);
    }
    
    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }
    
    public Product toggleProductAvailability(Long id) {
        Optional<Product> productOpt = productRepository.findById(id);
        if (productOpt.isPresent()) {
            Product product = productOpt.get();
            product.setIsAvailable(!product.getIsAvailable());
            return productRepository.save(product);
        }
        throw new RuntimeException("Product not found with id: " + id);
    }
    
    public Product updateStock(Long id, Integer quantity) {
        Optional<Product> productOpt = productRepository.findById(id);
        if (productOpt.isPresent()) {
            Product product = productOpt.get();
            product.setStockQuantity(quantity);
            if (quantity <= 0) {
                product.setIsAvailable(false);
            }
            return productRepository.save(product);
        }
        throw new RuntimeException("Product not found with id: " + id);
    }
    
    public boolean isProductAvailable(Long productId, Integer requestedQuantity) {
        Optional<Product> productOpt = productRepository.findById(productId);
        if (productOpt.isPresent()) {
            Product product = productOpt.get();
            return product.getIsAvailable() && 
                   (product.getStockQuantity() == null || product.getStockQuantity() >= requestedQuantity);
        }
        return false;
    }
}
