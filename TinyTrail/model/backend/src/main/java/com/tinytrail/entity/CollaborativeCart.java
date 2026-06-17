package com.tinytrail.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "collaborative_cart")
public class CollaborativeCart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cart_code", unique = true, length = 16)
    private String cartCode;

    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CartItem> items = new ArrayList<>();

    @Column(name = "expires_at")
    private Instant expiresAt;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "cart_participants",
            joinColumns = @JoinColumn(name = "cart_id"),
            inverseJoinColumns = @JoinColumn(name = "user_id"))
    private Set<User> participants = new HashSet<>();

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCartCode() { return cartCode; }
    public void setCartCode(String cartCode) { this.cartCode = cartCode; }
    public List<CartItem> getItems() { return items; }
    public void setItems(List<CartItem> items) { this.items = items; }
    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
    public Set<User> getParticipants() { return participants; }
    public void setParticipants(Set<User> participants) { this.participants = participants; }
}
