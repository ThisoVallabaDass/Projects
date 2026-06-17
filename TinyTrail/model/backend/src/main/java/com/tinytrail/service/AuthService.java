package com.tinytrail.service;

import com.tinytrail.dto.AuthRequest;
import com.tinytrail.dto.AuthResponse;
import com.tinytrail.entity.User;
import com.tinytrail.repository.UserRepository;
import com.tinytrail.security.JwtTokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenUtil jwtTokenUtil;

    public AuthResponse login(AuthRequest authRequest) {
        User user = userRepository.findByUsername(authRequest.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(authRequest.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        String token = jwtTokenUtil.generateToken(user.getUsername());
        return new AuthResponse(token, new AuthResponse.UserDto(user));
    }

    public AuthResponse register(AuthRequest authRequest) {
        if (userRepository.existsByUsername(authRequest.getUsername())) {
            throw new RuntimeException("Username already exists");
        }

        if (authRequest.getEmail() != null && userRepository.existsByEmail(authRequest.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        User user = new User();
        user.setUsername(authRequest.getUsername());
        user.setPassword(passwordEncoder.encode(authRequest.getPassword()));
        user.setEmail(authRequest.getEmail());
        user.setPhone(authRequest.getPhone());
        user.setRole(User.Role.BUYER);

        user = userRepository.save(user);

        String token = jwtTokenUtil.generateToken(user.getUsername());
        return new AuthResponse(token, new AuthResponse.UserDto(user));
    }

    public AuthResponse.UserDto getCurrentUser(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return new AuthResponse.UserDto(user);
    }
}
