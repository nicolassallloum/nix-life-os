from datetime import datetime, timedelta
from decimal import Decimal
import psycopg2
import psycopg2.extras
import os


DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_DATABASE", "nixlifeos_db")
DB_USER = os.getenv("DB_USERNAME", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


def calculate_weight_prediction(user_id: str, days_ahead: int = 30):
    """
    Predict user weight using simple linear average daily change.
    """

    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("""
        SELECT
            log_date,
            weight_kg
        FROM health_weight_logs
        WHERE user_id = %s
        ORDER BY log_date ASC
    """, (user_id,))

    rows = cur.fetchall()

    if len(rows) < 2:
        cur.close()
        conn.close()

        return {
            "status": "insufficient_data",
            "message": "At least 2 weight logs are required for prediction.",
            "user_id": user_id
        }

    first_log = rows[0]
    latest_log = rows[-1]

    first_date = first_log["log_date"]
    latest_date = latest_log["log_date"]

    first_weight = float(first_log["weight_kg"])
    latest_weight = float(latest_log["weight_kg"])

    days_between = (latest_date - first_date).days

    if days_between <= 0:
        average_daily_change = 0
    else:
        average_daily_change = (latest_weight - first_weight) / days_between

    predicted_weight = latest_weight + (average_daily_change * days_ahead)
    target_date = latest_date + timedelta(days=days_ahead)

    change_value = predicted_weight - latest_weight

    if latest_weight > 0:
        change_percentage = (change_value / latest_weight) * 100
    else:
        change_percentage = 0

    confidence_level = "medium"

    if len(rows) >= 10:
        confidence_level = "high"
    elif len(rows) < 5:
        confidence_level = "low"

    result = {
        "status": "success",
        "user_id": user_id,
        "prediction_type": "weight_prediction",
        "prediction_date": datetime.now().date().isoformat(),
        "target_date": target_date.isoformat(),
        "current_weight": round(latest_weight, 2),
        "predicted_weight": round(predicted_weight, 2),
        "change_value": round(change_value, 2),
        "change_percentage": round(change_percentage, 2),
        "average_daily_change": round(average_daily_change, 4),
        "days_ahead": days_ahead,
        "logs_count": len(rows),
        "confidence_level": confidence_level,
        "input_summary": {
            "first_date": first_date.isoformat(),
            "first_weight": first_weight,
            "latest_date": latest_date.isoformat(),
            "latest_weight": latest_weight,
            "days_between": days_between
        }
    }

    cur.execute("""
        INSERT INTO ai_predictions (
            id,
            user_id,
            prediction_type,
            prediction_date,
            target_date,
            current_value,
            predicted_value,
            change_value,
            change_percentage,
            input_summary,
            prediction_payload,
            confidence_level,
            notes,
            created_at,
            updated_at
        )
        VALUES (
            gen_random_uuid(),
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s::jsonb,
            %s::jsonb,
            %s,
            %s,
            NOW(),
            NOW()
        )
    """, (
        user_id,
        "weight_prediction",
        result["prediction_date"],
        result["target_date"],
        result["current_weight"],
        result["predicted_weight"],
        result["change_value"],
        result["change_percentage"],
        psycopg2.extras.Json(result["input_summary"]),
        psycopg2.extras.Json(result),
        confidence_level,
        "Weight prediction generated using linear average daily change."
    ))

    conn.commit()

    cur.close()
    conn.close()

    return result