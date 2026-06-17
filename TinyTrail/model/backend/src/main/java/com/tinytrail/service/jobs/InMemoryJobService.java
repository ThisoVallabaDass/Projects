package com.tinytrail.service.jobs;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class InMemoryJobService {

    private final Map<String, Job> jobs = new ConcurrentHashMap<>();

    public String createJob(String type, Map<String, Object> payload) {
        String id = UUID.randomUUID().toString();
        Job j = new Job(id, type, payload, "PENDING", Instant.now());
        jobs.put(id, j);
        // Immediately mark SUCCESS for mocks (in real impl: async processing)
        j.setStatus("SUCCESS");
        j.setResult(Map.of("previewUrl", "https://via.placeholder.com/300", "jobId", id));
        return id;
    }

    public Job getJob(String id) {
        return jobs.get(id);
    }

    public static class Job {
        private String id;
        private String type;
        private Map<String,Object> payload;
        private String status;
        private Instant createdAt;
        private Map<String,Object> result;

        public Job(String id, String type, Map<String,Object> payload, String status, Instant createdAt) {
            this.id = id; this.type = type; this.payload = payload; this.status = status; this.createdAt = createdAt;
        }

        public String getId() { return id; }
        public String getType() { return type; }
        public Map<String,Object> getPayload() { return payload; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getCreatedAt() { return createdAt; }
        public Map<String,Object> getResult() { return result; }
        public void setResult(Map<String,Object> result) { this.result = result; }
    }
}
