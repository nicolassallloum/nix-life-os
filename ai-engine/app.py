from fastapi import FastAPI
from datetime import datetime

app = FastAPI(
    title="NIX LIFE OS AI Engine",
    version="1.0.0"
)

@app.get("/")
def root():
    return {
        "service": "NIX LIFE OS AI Engine",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "ai-engine"
    }

@app.get("/api/ai/daily-insights")
def daily_insights():
    return {
        "status": "success",
        "message": "Daily AI insights engine is running.",
        "data": {
            "finance": "Finance analysis ready.",
            "health": "Health analysis ready.",
            "projects": "Project analysis ready."
        }
    }
