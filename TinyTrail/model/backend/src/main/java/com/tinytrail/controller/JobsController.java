package com.tinytrail.controller;

import com.tinytrail.service.jobs.InMemoryJobService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/jobs")
public class JobsController {

    private final InMemoryJobService jobService;

    public JobsController(InMemoryJobService jobService) {
        this.jobService = jobService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> createJob(@RequestBody Map<String,Object> body) {
        String type = (String) body.getOrDefault("type", "image_generation");
        String id = jobService.createJob(type, body);
        return ResponseEntity.ok(Map.of("jobId", id));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getJob(@PathVariable String id) {
        InMemoryJobService.Job j = jobService.getJob(id);
        if (j == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(Map.of("id", j.getId(), "status", j.getStatus(), "result", j.getResult()));
    }
}
