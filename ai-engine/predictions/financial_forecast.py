from datetime import datetime, date
import calendar
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


def calculate_financial_forecast(user_id: str, target_month: str = None):
    """
    Forecast monthly finance using current month income/expenses.
    target_month format: YYYY-MM
    """

    today = date.today()

    if target_month:
        year, month = map(int, target_month.split("-"))
    else:
        year = today.year
        month = today.month

    first_day = date(year, month, 1)
    last_day = date(year, month, calendar.monthrange(year, month)[1])

    if today.year == year and today.month == month:
        elapsed_days = today.day
        remaining_days = (last_day - today).days
    else:
        elapsed_days = (last_day - first_day).days + 1
        remaining_days = 0

    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # Current total balance
    cur.execute("""
        SELECT
            COALESCE(SUM(current_balance), 0) AS total_balance
        FROM nix_life_os.finance_account
        WHERE user_id = %s
    """, (user_id,))

    balance_row = cur.fetchone()
    current_balance = float(balance_row["total_balance"] or 0)

    # Income and expenses for current month
    cur.execute("""
        SELECT
            COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
            COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) AS total_expenses
        FROM nix_life_os.finance_transaction
        WHERE user_id = %s
          AND transaction_date BETWEEN %s AND %s
    """, (user_id, first_day, today))

    tx_row = cur.fetchone()

    total_income = float(tx_row["total_income"] or 0)
    total_expenses = float(tx_row["total_expenses"] or 0)

    net_cash_flow = total_income - total_expenses

    if elapsed_days <= 0:
        average_daily_income = 0
        average_daily_expenses = 0
        average_daily_net = 0
    else:
        average_daily_income = total_income / elapsed_days
        average_daily_expenses = total_expenses / elapsed_days
        average_daily_net = net_cash_flow / elapsed_days

    forecast_income = total_income + (average_daily_income * remaining_days)
    forecast_expenses = total_expenses + (average_daily_expenses * remaining_days)
    forecast_net_cash_flow = forecast_income - forecast_expenses
    forecast_balance = current_balance + (average_daily_net * remaining_days)

    if current_balance > 0:
        change_percentage = ((forecast_balance - current_balance) / current_balance) * 100
    else:
        change_percentage = 0

    confidence_level = "medium"

    if elapsed_days >= 20:
        confidence_level = "high"
    elif elapsed_days < 7:
        confidence_level = "low"

    result = {
        "status": "success",
        "user_id": user_id,
        "prediction_type": "financial_forecast",
        "prediction_date": today.isoformat(),
        "target_date": last_day.isoformat(),
        "month": f"{year}-{str(month).zfill(2)}",
        "current_balance": round(current_balance, 2),
        "total_income_so_far": round(total_income, 2),
        "total_expenses_so_far": round(total_expenses, 2),
        "net_cash_flow_so_far": round(net_cash_flow, 2),
        "average_daily_income": round(average_daily_income, 2),
        "average_daily_expenses": round(average_daily_expenses, 2),
        "average_daily_net": round(average_daily_net, 2),
        "forecast_income": round(forecast_income, 2),
        "forecast_expenses": round(forecast_expenses, 2),
        "forecast_net_cash_flow": round(forecast_net_cash_flow, 2),
        "forecast_balance": round(forecast_balance, 2),
        "change_value": round(forecast_balance - current_balance, 2),
        "change_percentage": round(change_percentage, 2),
        "elapsed_days": elapsed_days,
        "remaining_days": remaining_days,
        "confidence_level": confidence_level,
        "input_summary": {
            "first_day": first_day.isoformat(),
            "last_day": last_day.isoformat(),
            "calculation_until": today.isoformat(),
            "elapsed_days": elapsed_days,
            "remaining_days": remaining_days
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
        "financial_forecast",
        result["prediction_date"],
        result["target_date"],
        result["current_balance"],
        result["forecast_balance"],
        result["change_value"],
        result["change_percentage"],
        psycopg2.extras.Json(result["input_summary"]),
        psycopg2.extras.Json(result),
        confidence_level,
        "Financial forecast generated using average daily cash flow."
    ))

    conn.commit()

    cur.close()
    conn.close()

    return result