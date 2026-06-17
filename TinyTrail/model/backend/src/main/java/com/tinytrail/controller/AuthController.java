package com.tinytrail.controller;

import com.tinytrail.dto.AuthRequest;
import com.tinytrail.dto.AuthResponse;
import com.tinytrail.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@Tag(name = "Authentication", description = "Authentication endpoints")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticate user and return JWT token")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody AuthRequest authRequest) {
        try {
            AuthResponse response = authService.login(authRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/register")
    @Operation(summary = "User registration", description = "Register a new user")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody AuthRequest authRequest) {
        try {
            AuthResponse response = authService.register(authRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/me")
    @Operation(summary = "Get current user", description = "Get current authenticated user details")
    public ResponseEntity<AuthResponse.UserDto> getCurrentUser(Authentication authentication) {
        try {
            AuthResponse.UserDto user = authService.getCurrentUser(authentication.getName());
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
