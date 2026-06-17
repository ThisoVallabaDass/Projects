package com.tinytrail.controller;

import com.tinytrail.entity.CartItem;
import com.tinytrail.entity.CollaborativeCart;
import com.tinytrail.repository.CartItemRepository;
import com.tinytrail.repository.CollaborativeCartRepository;
import com.tinytrail.service.collab.CollaborativeCartService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/cart")
public class CartController {

    private final CollaborativeCartRepository cartRepository;
    private final CartItemRepository itemRepository;
    private final CollaborativeCartService cartService;

    public CartController(CollaborativeCartRepository cartRepository, CartItemRepository itemRepository, CollaborativeCartService cartService) {
        this.cartRepository = cartRepository;
        this.itemRepository = itemRepository;
        this.cartService = cartService;
    }

    @PostMapping("/draft")
    public ResponseEntity<?> createDraft(@RequestBody Map<String, Object> body) {
        // Create a lightweight draft cart (not persisted as collaborative cart) or attach to existing
        // For simplicity, create a CollaborativeCart with items
        CollaborativeCart cart = new CollaborativeCart();
        String code = cartService.generateCode();
        cart.setCartCode(code);
        cartRepository.save(cart);
        return ResponseEntity.created(URI.create("/api/cart/" + cart.getId())).body(Map.of("code", code, "id", cart.getId()));
    }

    @PostMapping("/{code}/add")
    public ResponseEntity<?> addItem(@PathVariable String code, @RequestBody Map<String, Object> body) {
        Optional<CollaborativeCart> cartOpt = cartRepository.findByCartCode(code);
        if (cartOpt.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Cart not found"));
        CollaborativeCart cart = cartOpt.get();

        Long productId = ((Number) body.getOrDefault("productId", 0)).longValue();
        Integer qty = ((Number) body.getOrDefault("quantity", 1)).intValue();
        Long userId = body.get("userId") == null ? null : ((Number) body.get("userId")).longValue();

        CartItem item = new CartItem();
        item.setCart(cart);
        item.setProductId(productId);
        item.setQuantity(qty);
        item.setAddedByUserId(userId);
        itemRepository.save(item);

        // Refresh cart items and broadcast
        cart.getItems().add(item);
        cartRepository.save(cart);
        cartService.broadcastCartUpdate(cart);

        return ResponseEntity.ok(Map.of("ok", true));
    }

    @PostMapping("/{code}/remove")
    public ResponseEntity<?> removeItem(@PathVariable String code, @RequestBody Map<String, Object> body) {
        Optional<CollaborativeCart> cartOpt = cartRepository.findByCartCode(code);
        if (cartOpt.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Cart not found"));
        CollaborativeCart cart = cartOpt.get();

        Long itemId = ((Number) body.getOrDefault("itemId", 0)).longValue();
        Optional<CartItem> itOpt = itemRepository.findById(itemId);
        if (itOpt.isPresent()) {
            CartItem it = itOpt.get();
            itemRepository.delete(it);
            cart.getItems().removeIf(ci -> ci.getId().equals(itemId));
            cartRepository.save(cart);
            cartService.broadcastCartUpdate(cart);
            return ResponseEntity.ok(Map.of("ok", true));
        }
        return ResponseEntity.status(404).body(Map.of("error","Item not found"));
    }
}
