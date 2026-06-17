package com.tinytrail.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class AuthRequest {
    
    @NotBlank
    @Size(max = 100)
    private String username;
    
    @NotBlank
    @Size(max = 255)
    private String password;
    
    @Email
    @Size(max = 100)
    private String email;
    
    @Size(max = 20)
    private String phone;
    
    // Constructors
    public AuthRequest() {}
    
    public AuthRequest(String username, String password) {
        this.username = username;
        this.password = password;
    }
    
    public AuthRequest(String username, String password, String email, String phone) {
        this.username = username;
        this.password = password;
        this.email = email;
        this.phone = phone;
    }
    
    // Getters and Setters
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
}
