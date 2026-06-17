package com.tinytrail.realtime;

import com.tinytrail.model.CartItem;
import com.tinytrail.model.CollaborativeCart;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class CollaborativeCartService {

    private final SimpMessagingTemplate messagingTemplate;
    private final Map<String, CollaborativeCart> carts = new ConcurrentHashMap<>();

    public CollaborativeCartService(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public CollaborativeCart createCart() {
        CollaborativeCart c = new CollaborativeCart();
        String code = generateCode();
        c.setCartCode(code);
        c.setExpiresAt(Instant.now().plusSeconds(60 * 60 * 24));
        carts.put(code, c);
        broadcast(code, c);
        return c;
    }

    public Optional<CollaborativeCart> findByCode(String code) {
        return Optional.ofNullable(carts.get(code));
    }

    public void addItem(String code, CartItem item) {
        CollaborativeCart c = carts.get(code);
        if (c == null) return;
        item.setCart(c);
        c.getItems().add(item);
        broadcast(code, c);
    }

    private void broadcast(String code, CollaborativeCart cart) {
        messagingTemplate.convertAndSend("/topic/cart/" + code, cart);
    }

    private String generateCode() {
        String uuid = UUID.randomUUID().toString().replaceAll("-", "");
        return uuid.substring(0,6).toUpperCase();
    }
}
