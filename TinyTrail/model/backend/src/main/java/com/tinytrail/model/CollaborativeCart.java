package com.tinytrail.model;

import javax.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "collaborative_cart")
public class CollaborativeCart {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String cartCode;

    private Instant expiresAt;

    private Instant createdAt = Instant.now();

    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> items = new ArrayList<>();

    public CollaborativeCart() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCartCode() { return cartCode; }
    public void setCartCode(String cartCode) { this.cartCode = cartCode; }
    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
    public Instant getCreatedAt() { return createdAt; }
    public List<CartItem> getItems() { return items; }
    public void setItems(List<CartItem> items) { this.items = items; }
}
