package com.tinytrail.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "cart_item")
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cart_id")
    private CollaborativeCart cart;

    private Long productId;

    private Integer quantity = 1;

    private Long addedByUserId;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public CollaborativeCart getCart() { return cart; }
    public void setCart(CollaborativeCart cart) { this.cart = cart; }
    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Long getAddedByUserId() { return addedByUserId; }
    public void setAddedByUserId(Long addedByUserId) { this.addedByUserId = addedByUserId; }
}
