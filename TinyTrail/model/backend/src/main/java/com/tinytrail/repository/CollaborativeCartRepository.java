package com.tinytrail.repository;

import com.tinytrail.entity.CollaborativeCart;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CollaborativeCartRepository extends JpaRepository<CollaborativeCart, Long> {
    Optional<CollaborativeCart> findByCartCode(String cartCode);
}
