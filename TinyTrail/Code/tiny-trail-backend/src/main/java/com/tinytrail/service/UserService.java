package com.tinytrail.service;

import com.tinytrail.entity.User;
import com.tinytrail.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    public User createUser(User user) {
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }
    
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }
    
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }
    
    public User updateUser(User user) {
        return userRepository.save(user);
    }
    
    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
    
    public List<User> findAllUsers() {
        return userRepository.findAll();
    }
    
    public List<User> findUsersByRole(User.Role role) {
        return userRepository.findByRole(role);
    }
    
    public List<User> findUsersByPincode(String pincode) {
        return userRepository.findByPincode(pincode);
    }
    
    public List<User> findEntrepreneursByPincode(String pincode) {
        return userRepository.findActiveUsersByRoleAndPincode(User.Role.ENTREPRENEUR, pincode);
    }
    
    public List<User> findActiveUsers() {
        return userRepository.findAllActiveUsers();
    }
    
    public User deactivateUser(Long id) {
        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            user.setIsActive(false);
            return userRepository.save(user);
        }
        throw new RuntimeException("User not found with id: " + id);
    }
    
    public User activateUser(Long id) {
        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            user.setIsActive(true);
            return userRepository.save(user);
        }
        throw new RuntimeException("User not found with id: " + id);
    }
}
