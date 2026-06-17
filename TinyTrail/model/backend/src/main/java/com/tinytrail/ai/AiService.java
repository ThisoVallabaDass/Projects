package com.tinytrail.ai;

import com.tinytrail.ai.dto.AiRequest;
import com.tinytrail.ai.dto.AiResponse;

public interface AiService {
    // TODO: implement production integration (OpenAI/Anthropic/etc.)
    AiResponse query(AiRequest request);
}
