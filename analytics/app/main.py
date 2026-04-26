from fastapi import FastAPI
from app.schemas.health_analytics_schema import (
    HealthAnalyticsRequest,
    HealthAnalyticsResponse,
)
from app.services.health_analytics_service import HealthAnalyticsService

app = FastAPI(
    title="NIX LIFE OS - Health Analytics Engine",
    version="1.0.0",
    description="Python analytics service for health, nutrition, hydration, weight, steps, CKD alerts, and health scoring.",
)

analytics_service = HealthAnalyticsService()


@app.get("/")
def root():
    return {
        "success": True,
        "message": "NIX LIFE OS Health Analytics Engine is running",
    }


@app.get("/health")
def health_check():
    return {
        "success": True,
        "service": "health-analytics-engine",
        "status": "healthy",
    }


@app.post("/api/v1/analytics/health/daily", response_model=HealthAnalyticsResponse)
def calculate_daily_health_analytics(payload: HealthAnalyticsRequest):
    return analytics_service.calculate_daily_analytics(payload)
