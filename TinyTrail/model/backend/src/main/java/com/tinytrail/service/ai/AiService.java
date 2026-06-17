package com.tinytrail.service.ai;

import com.tinytrail.service.ai.dto.AiRequest;
import com.tinytrail.service.ai.dto.AiResponse;

public interface AiService {
    AiResponse query(AiRequest request);
}
