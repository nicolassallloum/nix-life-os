from typing import List, Optional
from pydantic import BaseModel, Field


class WeightLog(BaseModel):
    log_date: str
    weight_kg: float


class NutritionSummary(BaseModel):
    log_date: str
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    sodium_mg: float = 0
    potassium_mg: float = 0
    phosphorus_mg: float = 0
    sugar_g: float = 0
    fiber_g: float = 0


class HydrationSummary(BaseModel):
    log_date: str
    total_fluids_ml: float = 0
    water_ml: float = 0
    other_drinks_ml: float = 0


class StepsSummary(BaseModel):
    log_date: str
    steps: int = 0
    distance_km: Optional[float] = 0
    active_minutes: Optional[int] = 0


class UserHealthProfile(BaseModel):
    weight_kg: float = Field(default=64)
    height_cm: float = Field(default=155)
    age: int = Field(default=29)
    gender: str = Field(default="male")
    activity_level: str = Field(default="light")
    ckd_safe_mode: bool = Field(default=True)
    sodium_limit_mg: float = Field(default=2000)
    fluid_min_ml: float = Field(default=1500)
    fluid_max_ml: float = Field(default=2500)


class HealthAnalyticsRequest(BaseModel):
    user_id: str
    target_date: str
    profile: UserHealthProfile
    weight_logs: List[WeightLog] = []
    nutrition: Optional[NutritionSummary] = None
    hydration: Optional[HydrationSummary] = None
    steps: Optional[StepsSummary] = None


class AlertItem(BaseModel):
    type: str
    level: str
    message: str
    value: Optional[float] = None
    limit: Optional[float] = None


class HealthAnalyticsResponse(BaseModel):
    success: bool
    message: str
    user_id: str
    target_date: str

    estimated_bmr: float
    estimated_tdee: float
    estimated_steps_burn: float
    estimated_total_burn: float

    calorie_balance: float
    weight_prediction_7_days_kg: Optional[float]
    weight_prediction_30_days_kg: Optional[float]

    health_score: int
    health_score_label: str

    alerts: List[AlertItem]
    recommendations: List[str]
