import io
import json
import random
from typing import List, Optional
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="TinyTrail Hygiene Service")

# Add CORS middleware to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class BoundingBox(BaseModel):
    x: float
    y: float
    width: float
    height: float


class Anomaly(BaseModel):
    issue: str
    box: List[float]  # [x, y, width, height]


class VerifyResponse(BaseModel):
    status: str  # 'passed' or 'failed'
    anomalies: Optional[List[Anomaly]] = None
    message: str


class BaselineResponse(BaseModel):
    status: str
    message: str


# Mock AI Logic
def generate_mock_anomalies() -> List[dict]:
    """Generate random anomalies for demonstration."""
    anomaly_types = [
        "Spill on counter",
        "Dirty surface detected",
        "Food residue found",
        "Stain on work area",
        "Unwashed hands area",
        "Dust accumulation",
    ]

    num_anomalies = random.randint(1, 3)
    anomalies = []

    for _ in range(num_anomalies):
        anomalies.append(
            {
                "issue": random.choice(anomaly_types),
                "box": [
                    random.uniform(0.1, 0.8),  # x
                    random.uniform(0.1, 0.8),  # y
                    random.uniform(0.1, 0.4),  # width
                    random.uniform(0.1, 0.4),  # height
                ],
            }
        )

    return anomalies


@app.post("/train-baseline", response_model=BaselineResponse)
async def train_baseline(files: List[UploadFile] = File(...)):
    """
    Accept 5 baseline images and train the AI model.
    In production, this would process the images and train a baseline model.
    For mock purposes, we just validate that we received 5 images.
    """
    if len(files) != 5:
        raise HTTPException(
            status_code=400,
            detail=f"Expected 5 images, received {len(files)}",
        )

    # Validate each file
    for idx, file in enumerate(files):
        if file.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
            raise HTTPException(
                status_code=400,
                detail=f"File {idx + 1} is not a valid image format",
            )

        # Read file to validate it's not empty
        content = await file.read()
        if len(content) < 1000:
            raise HTTPException(
                status_code=400,
                detail=f"File {idx + 1} is too small or invalid",
            )

    # In production, process baseline images here
    # For now, we just acknowledge receipt

    return BaselineResponse(
        status="baseline_saved",
        message="Successfully trained baseline model with 5 photos",
    )


@app.post("/verify-daily", response_model=VerifyResponse)
async def verify_daily(file: UploadFile = File(...)):
    """
    Accept a single daily shift photo and verify hygiene status.
    Uses mock AI logic to determine pass/fail.
    """
    # Validate file
    if file.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
        raise HTTPException(
            status_code=400,
            detail="File is not a valid image format",
        )

    content = await file.read()
    if len(content) < 1000:
        raise HTTPException(
            status_code=400,
            detail="Image is too small or invalid",
        )

    # Mock AI Logic: 60% pass rate
    passed = random.random() > 0.4

    if passed:
        return VerifyResponse(
            status="passed",
            message="Hygiene check passed! Your workspace looks clean.",
        )
    else:
        # Generate random anomalies
        anomalies_data = generate_mock_anomalies()
        anomalies = [
            Anomaly(issue=a["issue"], box=a["box"]) for a in anomalies_data
        ]

        return VerifyResponse(
            status="failed",
            anomalies=anomalies,
            message="Hygiene check failed. Please clean the highlighted areas and retry.",
        )


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "TinyTrail Hygiene Service"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
