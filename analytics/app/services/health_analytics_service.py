from statistics import mean
from app.schemas.health_analytics_schema import (
    HealthAnalyticsRequest,
    HealthAnalyticsResponse,
    AlertItem,
)


class HealthAnalyticsService:
    def calculate_daily_analytics(self, payload: HealthAnalyticsRequest) -> HealthAnalyticsResponse:
        profile = payload.profile
        nutrition = payload.nutrition
        hydration = payload.hydration
        steps = payload.steps

        current_weight = self._resolve_current_weight(payload)
        bmr = self._calculate_bmr(
            weight_kg=current_weight,
            height_cm=profile.height_cm,
            age=profile.age,
            gender=profile.gender,
        )

        tdee = self._calculate_tdee(bmr, profile.activity_level)

        steps_count = steps.steps if steps else 0
        estimated_steps_burn = self._estimate_steps_calorie_burn(
            steps=steps_count,
            weight_kg=current_weight,
        )

        estimated_total_burn = tdee + estimated_steps_burn

        calories_in = nutrition.calories if nutrition else 0
        calorie_balance = calories_in - estimated_total_burn

        weight_prediction_7 = self._predict_weight_change(
            current_weight=current_weight,
            daily_calorie_balance=calorie_balance,
            days=7,
        )

        weight_prediction_30 = self._predict_weight_change(
            current_weight=current_weight,
            daily_calorie_balance=calorie_balance,
            days=30,
        )

        alerts = self._generate_ckd_alerts(payload)
        health_score = self._calculate_health_score(payload, calorie_balance, alerts)
        health_score_label = self._score_label(health_score)
        recommendations = self._generate_recommendations(payload, calorie_balance, alerts)

        return HealthAnalyticsResponse(
            success=True,
            message="Daily health analytics calculated successfully",
            user_id=payload.user_id,
            target_date=payload.target_date,
            estimated_bmr=round(bmr, 2),
            estimated_tdee=round(tdee, 2),
            estimated_steps_burn=round(estimated_steps_burn, 2),
            estimated_total_burn=round(estimated_total_burn, 2),
            calorie_balance=round(calorie_balance, 2),
            weight_prediction_7_days_kg=round(weight_prediction_7, 2),
            weight_prediction_30_days_kg=round(weight_prediction_30, 2),
            health_score=health_score,
            health_score_label=health_score_label,
            alerts=alerts,
            recommendations=recommendations,
        )

    def _resolve_current_weight(self, payload: HealthAnalyticsRequest) -> float:
        if payload.weight_logs:
            sorted_logs = sorted(payload.weight_logs, key=lambda x: x.log_date)
            return sorted_logs[-1].weight_kg

        return payload.profile.weight_kg

    def _calculate_bmr(self, weight_kg: float, height_cm: float, age: int, gender: str) -> float:
        """
        Mifflin-St Jeor equation.
        Male:   10W + 6.25H - 5A + 5
        Female: 10W + 6.25H - 5A - 161
        """
        gender_normalized = gender.lower().strip()

        if gender_normalized == "female":
            return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161

        return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5

    def _calculate_tdee(self, bmr: float, activity_level: str) -> float:
        factors = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9,
        }

        factor = factors.get(activity_level.lower().strip(), 1.375)
        return bmr * factor

    def _estimate_steps_calorie_burn(self, steps: int, weight_kg: float) -> float:
        """
        Simple estimation:
        Average burn ≈ 0.04 kcal per step for average adult.
        Adjust slightly by weight.
        """
        base_kcal_per_step = 0.04
        weight_factor = weight_kg / 70
        return steps * base_kcal_per_step * weight_factor

    def _predict_weight_change(self, current_weight: float, daily_calorie_balance: float, days: int) -> float:
        """
        Approximation:
        7700 kcal ≈ 1 kg body weight.
        Negative balance predicts loss.
        Positive balance predicts gain.
        """
        expected_change_kg = (daily_calorie_balance * days) / 7700
        return current_weight + expected_change_kg

    def _generate_ckd_alerts(self, payload: HealthAnalyticsRequest) -> list[AlertItem]:
        alerts = []
        profile = payload.profile
        nutrition = payload.nutrition
        hydration = payload.hydration

        if not profile.ckd_safe_mode:
            return alerts

        if nutrition:
            if nutrition.sodium_mg > profile.sodium_limit_mg:
                alerts.append(
                    AlertItem(
                        type="CKD_SODIUM_LIMIT",
                        level="high",
                        message="Sodium intake is above your configured CKD-safe daily limit.",
                        value=nutrition.sodium_mg,
                        limit=profile.sodium_limit_mg,
                    )
                )

            if nutrition.sodium_mg >= profile.sodium_limit_mg * 0.85 and nutrition.sodium_mg <= profile.sodium_limit_mg:
                alerts.append(
                    AlertItem(
                        type="CKD_SODIUM_WARNING",
                        level="medium",
                        message="Sodium intake is close to your configured CKD-safe daily limit.",
                        value=nutrition.sodium_mg,
                        limit=profile.sodium_limit_mg,
                    )
                )

        if hydration:
            if hydration.total_fluids_ml < profile.fluid_min_ml:
                alerts.append(
                    AlertItem(
                        type="CKD_LOW_HYDRATION",
                        level="medium",
                        message="Fluid intake is below your configured daily minimum.",
                        value=hydration.total_fluids_ml,
                        limit=profile.fluid_min_ml,
                    )
                )

            if hydration.total_fluids_ml > profile.fluid_max_ml:
                alerts.append(
                    AlertItem(
                        type="CKD_HIGH_HYDRATION",
                        level="high",
                        message="Fluid intake is above your configured daily maximum. Review this with your doctor if you have fluid restriction.",
                        value=hydration.total_fluids_ml,
                        limit=profile.fluid_max_ml,
                    )
                )

        return alerts

    def _calculate_health_score(
        self,
        payload: HealthAnalyticsRequest,
        calorie_balance: float,
        alerts: list[AlertItem],
    ) -> int:
        score = 100

        nutrition = payload.nutrition
        hydration = payload.hydration
        steps = payload.steps

        for alert in alerts:
            if alert.level == "high":
                score -= 20
            elif alert.level == "medium":
                score -= 10
            else:
                score -= 5

        if nutrition:
            if nutrition.calories <= 0:
                score -= 10

            if nutrition.protein_g > 60:
                score -= 5

        else:
            score -= 15

        if hydration:
            if hydration.total_fluids_ml <= 0:
                score -= 10
        else:
            score -= 10

        if steps:
            if steps.steps < 3000:
                score -= 10
            elif steps.steps >= 6000:
                score += 5
        else:
            score -= 5

        if calorie_balance > 800:
            score -= 10
        elif calorie_balance < -1000:
            score -= 10

        return max(0, min(100, score))

    def _score_label(self, score: int) -> str:
        if score >= 85:
            return "Excellent"
        if score >= 70:
            return "Good"
        if score >= 50:
            return "Needs Attention"
        return "High Risk"

    def _generate_recommendations(
        self,
        payload: HealthAnalyticsRequest,
        calorie_balance: float,
        alerts: list[AlertItem],
    ) -> list[str]:
        recommendations = []

        alert_types = {alert.type for alert in alerts}

        if "CKD_SODIUM_LIMIT" in alert_types:
            recommendations.append("Reduce high-sodium foods today and review packaged/restaurant food intake.")

        if "CKD_SODIUM_WARNING" in alert_types:
            recommendations.append("You are close to the sodium limit. Keep the next meals low in salt.")

        if "CKD_LOW_HYDRATION" in alert_types:
            recommendations.append("Hydration is below your configured target. Add fluids only if allowed by your doctor.")

        if "CKD_HIGH_HYDRATION" in alert_types:
            recommendations.append("Hydration is above your configured limit. This may be important if you have fluid restriction.")

        if payload.steps and payload.steps.steps < 3000:
            recommendations.append("Light walking can improve daily activity score if medically safe.")

        if calorie_balance > 500:
            recommendations.append("Calories are above estimated burn. Consider a lighter next meal.")

        if calorie_balance < -900:
            recommendations.append("Calories are much lower than estimated burn. Avoid aggressive restriction unless supervised.")

        if not recommendations:
            recommendations.append("Your daily health indicators look balanced based on the available data.")

        return recommendations
