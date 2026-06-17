package com.tinytrail.controller;

import com.tinytrail.model.CartItem;
import com.tinytrail.model.CollaborativeCart;
import com.tinytrail.realtime.CollaborativeCartService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/carts")
public class CollaborativeCartController {

    private final CollaborativeCartService cartService;

    public CollaborativeCartController(CollaborativeCartService cartService) {
        this.cartService = cartService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> create() {
        CollaborativeCart c = cartService.createCart();
        Map<String,Object> r = new HashMap<>();
        r.put("code", c.getCartCode());
        r.put("expiresAt", c.getExpiresAt());
        return ResponseEntity.ok(r);
    }

    @PostMapping("/join")
    public ResponseEntity<?> join(@RequestBody Map<String,String> body) {
        String code = body.get("code");
        if (code == null) return ResponseEntity.badRequest().body("code required");
        return cartService.findByCode(code)
                .map(c -> ResponseEntity.ok(c))
                .orElseGet(() -> ResponseEntity.status(404).body("not found"));
    }

    @PostMapping("/{code}/add")
    public ResponseEntity<?> addItem(@PathVariable String code, @RequestBody Map<String,Object> body) {
        Long productId = Long.valueOf(body.getOrDefault("productId", 0).toString());
        Integer qty = Integer.valueOf(body.getOrDefault("quantity", 1).toString());
        Long userId = Long.valueOf(body.getOrDefault("userId", 0).toString());
        CartItem item = new CartItem();
        item.setProductId(productId);
        item.setQuantity(qty);
        item.setAddedBy(userId);
        cartService.addItem(code, item);
        return ResponseEntity.ok().build();
    }
}
package com.tinytrail.controller;

import com.tinytrail.entity.CollaborativeCart;
import com.tinytrail.repository.CollaborativeCartRepository;
import com.tinytrail.service.collab.CollaborativeCartService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/carts")
public class CollaborativeCartController {

    private final CollaborativeCartRepository cartRepository;
    private final CollaborativeCartService cartService;

    public CollaborativeCartController(CollaborativeCartRepository cartRepository, CollaborativeCartService cartService) {
        this.cartRepository = cartRepository;
        this.cartService = cartService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> createCart(@RequestParam(required = false) Integer ttlHours) {
        CollaborativeCart cart = new CollaborativeCart();
        String code = cartService.generateCode();
        cart.setCartCode(code);
        cart.setExpiresAt(Instant.now().plusSeconds((ttlHours == null ? 48 : ttlHours) * 3600L));
        cartRepository.save(cart);
        return ResponseEntity.created(URI.create("/api/carts/" + cart.getId())).body(Map.of("code", code, "expiresAt", cart.getExpiresAt()));
    }

    @PostMapping("/join")
    public ResponseEntity<?> joinCart(@RequestParam String code) {
        Optional<CollaborativeCart> c = cartRepository.findByCartCode(code);
        if (c.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Invalid code"));
        return ResponseEntity.ok(c.get());
    }
}
