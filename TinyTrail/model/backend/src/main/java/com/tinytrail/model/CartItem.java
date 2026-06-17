package com.tinytrail.model;

import javax.persistence.*;

@Entity
@Table(name = "cart_item")
public class CartItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "cart_id")
    private CollaborativeCart cart;

    private Long productId;
    private Integer quantity;
    private Long addedBy;

    public CartItem() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public CollaborativeCart getCart() { return cart; }
    public void setCart(CollaborativeCart cart) { this.cart = cart; }
    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Long getAddedBy() { return addedBy; }
    public void setAddedBy(Long addedBy) { this.addedBy = addedBy; }
}
