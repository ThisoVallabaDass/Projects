package com.tinytrail.controller;

import com.tinytrail.dto.ApiResponse;
import com.tinytrail.dto.JwtResponse;
import com.tinytrail.dto.LoginRequest;
import com.tinytrail.dto.SignupRequest;
import com.tinytrail.entity.User;
import com.tinytrail.security.JwtUtils;
import com.tinytrail.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    @Autowired
    private AuthenticationManager authenticationManager;
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private JwtUtils jwtUtils;
    
    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword())
            );
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);
            
            User user = (User) authentication.getPrincipal();
            
            return ResponseEntity.ok(new JwtResponse(jwt, user.getId(), user.getName(), 
                                                   user.getEmail(), user.getRole(), user.getPincode()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Invalid email or password"));
        }
    }
    
    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signUpRequest) {
        try {
            if (userService.existsByEmail(signUpRequest.getEmail())) {
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Email is already taken!"));
            }
            
            // Create new user
            User user = new User(signUpRequest.getName(), signUpRequest.getEmail(),
                               signUpRequest.getPassword(), signUpRequest.getRole(),
                               signUpRequest.getPincode());
            
            if (signUpRequest.getPhoneNumber() != null) {
                user.setPhoneNumber(signUpRequest.getPhoneNumber());
            }
            
            User savedUser = userService.createUser(user);
            
            return ResponseEntity.ok(new ApiResponse(true, "User registered successfully!", 
                                                   new UserResponse(savedUser)));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error: " + e.getMessage()));
        }
    }
    
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            return ResponseEntity.ok(new ApiResponse(true, "User details retrieved successfully", 
                                                   new UserResponse(user)));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving user details"));
        }
    }
    
    // Inner class for user response
    public static class UserResponse {
        private Long id;
        private String name;
        private String email;
        private User.Role role;
        private String pincode;
        private String phoneNumber;
        
        public UserResponse(User user) {
            this.id = user.getId();
            this.name = user.getName();
            this.email = user.getEmail();
            this.role = user.getRole();
            this.pincode = user.getPincode();
            this.phoneNumber = user.getPhoneNumber();
        }
        
        // Getters
        public Long getId() { return id; }
        public String getName() { return name; }
        public String getEmail() { return email; }
        public User.Role getRole() { return role; }
        public String getPincode() { return pincode; }
        public String getPhoneNumber() { return phoneNumber; }
    }
}
