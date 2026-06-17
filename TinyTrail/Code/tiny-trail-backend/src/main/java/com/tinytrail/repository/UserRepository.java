package com.tinytrail.repository;

import com.tinytrail.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    Boolean existsByEmail(String email);
    
    List<User> findByRole(User.Role role);
    
    List<User> findByPincode(String pincode);
    
    List<User> findByRoleAndPincode(User.Role role, String pincode);
    
    @Query("SELECT u FROM User u WHERE u.role = :role AND u.pincode = :pincode AND u.isActive = true")
    List<User> findActiveUsersByRoleAndPincode(@Param("role") User.Role role, @Param("pincode") String pincode);
    
    @Query("SELECT u FROM User u WHERE u.isActive = true")
    List<User> findAllActiveUsers();
}
