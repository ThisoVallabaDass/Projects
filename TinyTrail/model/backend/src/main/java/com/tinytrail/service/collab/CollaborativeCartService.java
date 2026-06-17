package com.tinytrail.service.collab;

import com.tinytrail.entity.CollaborativeCart;
import com.tinytrail.repository.CollaborativeCartRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Random;

@Service
public class CollaborativeCartService {

    private final CollaborativeCartRepository cartRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final Random random = new Random();

    public CollaborativeCartService(CollaborativeCartRepository cartRepository, SimpMessagingTemplate messagingTemplate) {
        this.cartRepository = cartRepository;
        this.messagingTemplate = messagingTemplate;
    }

    public String generateCode() {
        // Simple 4-char alphanumeric code
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 4; i++) sb.append(chars.charAt(random.nextInt(chars.length())));
        return sb.toString();
    }

    public void broadcastCartUpdate(CollaborativeCart cart) {
        if (cart == null || cart.getCartCode() == null) return;
        String dest = "/topic/cart/" + cart.getCartCode();
        messagingTemplate.convertAndSend(dest, cart);
    }
}
