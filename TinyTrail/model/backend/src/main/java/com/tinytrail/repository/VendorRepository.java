package com.tinytrail.repository;

import com.tinytrail.entity.Vendor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface VendorRepository extends JpaRepository<Vendor, Long> {

    @Query("SELECT v FROM Vendor v WHERE v.pincode = :pincode")
    List<Vendor> findByPincode(@Param("pincode") String pincode);

    // TODO: Add geolocation-based search (radius) using PostGIS/coordinates
}
