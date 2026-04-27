import argparse
import json
import uuid
from datetime import datetime, date
from decimal import Decimal

from db import fetch_all, fetch_one, execute


def decimal_to_float(value):
    if isinstance(value, Decimal):
        return float(value)
    return value

def json_safe(value):
    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, (datetime, date)):
        return value.isoformat()

    if isinstance(value, dict):
        return {key: json_safe(val) for key, val in value.items()}

    if isinstance(value, list):
        return [json_safe(item) for item in value]

    return value

def insert_insight(user_id, insight_type, category, title, message, severity, score, metadata, insight_date):
    execute(
        """
        INSERT INTO ai_insights (
            id,
            user_id,
            insight_type,
            category,
            title,
            message,
            severity,
            score,
            metadata,
            insight_date,
            is_read,
            is_archived,
            created_at,
            updated_at
        )
        VALUES (
            %(id)s,
            %(user_id)s,
            %(insight_type)s,
            %(category)s,
            %(title)s,
            %(message)s,
            %(severity)s,
            %(score)s,
            %(metadata)s::jsonb,
            %(insight_date)s,
            false,
            false,
            NOW(),
            NOW()
        )
        """,
        {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "insight_type": insight_type,
            "category": category,
            "title": title,
            "message": message,
            "severity": severity,
            "score": score,
            "metadata": json.dumps(json_safe(metadata or {})),
            "insight_date": insight_date,
        },
    )


def insert_alert(user_id, alert_type, module, title, message, severity, risk_score, trigger_data, alert_date):
    execute(
        """
        INSERT INTO ai_alerts (
            id,
            user_id,
            alert_type,
            module,
            title,
            message,
            severity,
            risk_score,
            trigger_data,
            alert_date,
            is_resolved,
            created_at,
            updated_at
        )
        VALUES (
            %(id)s,
            %(user_id)s,
            %(alert_type)s,
            %(module)s,
            %(title)s,
            %(message)s,
            %(severity)s,
            %(risk_score)s,
            %(trigger_data)s::jsonb,
            %(alert_date)s,
            false,
            NOW(),
            NOW()
        )
        """,
        {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "alert_type": alert_type,
            "module": module,
            "title": title,
            "message": message,
            "severity": severity,
            "risk_score": risk_score,
            "trigger_data": json.dumps(json_safe(trigger_data or {})),
            "alert_date": alert_date,
        },
    )


def clear_existing_daily_data(user_id, target_date):
    execute(
        """
        DELETE FROM ai_insights
        WHERE user_id = %(user_id)s
        AND insight_date = %(target_date)s
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )

    execute(
        """
        DELETE FROM ai_alerts
        WHERE user_id = %(user_id)s
        AND alert_date = %(target_date)s
        AND is_resolved = false
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )


def get_finance_metrics(user_id, target_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) AS income_total,
            COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) AS expense_total,
            COALESCE(SUM(CASE WHEN transaction_type = 'transfer' THEN amount ELSE 0 END), 0) AS transfer_total,
            COUNT(*) AS transaction_count
        FROM nix_life_os.finance_transaction
        WHERE user_id = %(user_id)s
        AND transaction_date::date = %(target_date)s
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )


def get_health_metrics(user_id, target_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(amount_ml), 0) AS water_ml,
            COUNT(*) AS drink_count
        FROM health_hydration_logs
        WHERE user_id = %(user_id)s
        AND log_date::date = %(target_date)s
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )


def get_weight_metrics(user_id, target_date):
    return fetch_one(
        """
        SELECT
            weight_kg,
            log_date
        FROM health_weight_logs
        WHERE user_id = %(user_id)s
        AND log_date::date <= %(target_date)s
        ORDER BY log_date DESC
        LIMIT 1
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )


def get_steps_metrics(user_id, target_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(steps_count), 0) AS steps_count
        FROM health_step_log
        WHERE user_id = %(user_id)s
        AND log_date::date = %(target_date)s
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )


def get_project_metrics(user_id):
    return fetch_one(
        """
        SELECT
            COUNT(*) AS total_projects,
            COUNT(*) FILTER (WHERE status = 'in_progress') AS active_projects,
            COUNT(*) FILTER (WHERE status = 'completed') AS completed_projects,
            COUNT(*) FILTER (
                WHERE target_end_date IS NOT NULL
                AND target_end_date < CURRENT_DATE
                AND status != 'completed'
            ) AS overdue_projects,
            COALESCE(AVG(progress_percentage), 0) AS avg_progress
        FROM projects
        WHERE user_id = %(user_id)s
        """,
        {
            "user_id": user_id,
        },
    )


def analyze_finance(user_id, target_date):
    metrics = get_finance_metrics(user_id, target_date)

    income_total = decimal_to_float(metrics["income_total"])
    expense_total = decimal_to_float(metrics["expense_total"])
    transaction_count = metrics["transaction_count"]

    if transaction_count == 0:
        insert_insight(
            user_id,
            "finance",
            "finance",
            "No finance activity recorded today",
            "No income or expense transactions were recorded today. Add your transactions to keep your financial dashboard accurate.",
            "info",
            50,
            metrics,
            target_date,
        )
        return

    net = income_total - expense_total

    if net > 0:
        insert_insight(
            user_id,
            "finance",
            "finance",
            "Positive cash flow today",
            f"Today you recorded income of {income_total:.2f} and expenses of {expense_total:.2f}. Your net cash flow is positive at {net:.2f}.",
            "success",
            85,
            metrics,
            target_date,
        )
    elif net < 0:
        insert_insight(
            user_id,
            "finance",
            "finance",
            "Negative cash flow today",
            f"Today your expenses exceeded your income by {abs(net):.2f}. Review your spending categories to control the gap.",
            "warning",
            65,
            metrics,
            target_date,
        )

        insert_alert(
            user_id,
            "daily_negative_cashflow",
            "finance",
            "Daily spending exceeded income",
            f"Your daily net cash flow is negative by {abs(net):.2f}.",
            "warning",
            70,
            metrics,
            target_date,
        )

    if expense_total > 0 and income_total > 0:
        expense_ratio = expense_total / income_total

        if expense_ratio >= 0.8:
            insert_alert(
                user_id,
                "high_expense_ratio",
                "finance",
                "High expense ratio",
                f"Your expenses consumed {expense_ratio * 100:.1f}% of today's income.",
                "critical" if expense_ratio >= 1 else "warning",
                min(expense_ratio * 100, 100),
                {
                    "income_total": income_total,
                    "expense_total": expense_total,
                    "expense_ratio": expense_ratio,
                },
                target_date,
            )


def analyze_health(user_id, target_date):
    hydration = get_health_metrics(user_id, target_date)
    weight = get_weight_metrics(user_id, target_date)
    steps = get_steps_metrics(user_id, target_date)

    water_ml = decimal_to_float(hydration["water_ml"]) if hydration else 0
    steps_count = int(steps["steps_count"]) if steps else 0

    # CKD-safe reminder: this does not prescribe fluid amount.
    if water_ml == 0:
        insert_insight(
            user_id,
            "health",
            "health",
            "No hydration logged today",
            "No hydration entry was recorded today. Add your drinks to keep your health tracking accurate.",
            "info",
            45,
            {
                "water_ml": water_ml,
            },
            target_date,
        )
    elif water_ml < 1000:
        insert_alert(
            user_id,
            "hydration_low",
            "health",
            "Low hydration tracking",
            f"You logged only {water_ml:.0f} ml today. Follow your doctor-approved fluid target and keep tracking accurately.",
            "warning",
            65,
            {
                "water_ml": water_ml,
            },
            target_date,
        )
    else:
        insert_insight(
            user_id,
            "health",
            "health",
            "Hydration tracking completed",
            f"You logged {water_ml:.0f} ml of fluids today. Continue tracking based on your medical fluid guidance.",
            "success",
            80,
            {
                "water_ml": water_ml,
            },
            target_date,
        )

    if steps_count > 0:
        if steps_count >= 6000:
            severity = "success"
            title = "Strong activity day"
            message = f"You logged {steps_count:,} steps today. Good progress for daily movement."
            score = 85
        elif steps_count >= 3000:
            severity = "info"
            title = "Moderate activity day"
            message = f"You logged {steps_count:,} steps today. A short walk can help improve consistency."
            score = 65
        else:
            severity = "warning"
            title = "Low activity day"
            message = f"You logged {steps_count:,} steps today. Consider gentle movement if you feel well."
            score = 50

        insert_insight(
            user_id,
            "health",
            "health",
            title,
            message,
            severity,
            score,
            {
                "steps_count": steps_count,
            },
            target_date,
        )

    if weight:
        insert_insight(
            user_id,
            "health",
            "health",
            "Latest weight available",
            f"Your latest recorded weight is {float(weight['weight_kg']):.1f} kg.",
            "info",
            60,
            {
                "weight_kg": float(weight["weight_kg"]),
                "log_date": str(weight["log_date"]),
            },
            target_date,
        )


def analyze_projects(user_id, target_date):
    metrics = get_project_metrics(user_id)

    if not metrics:
        return

    total_projects = metrics["total_projects"]
    active_projects = metrics["active_projects"]
    overdue_projects = metrics["overdue_projects"]
    avg_progress = decimal_to_float(metrics["avg_progress"])

    if total_projects == 0:
        insert_insight(
            user_id,
            "project",
            "projects",
            "No projects created yet",
            "Create your first project to start tracking progress inside NIX LIFE OS.",
            "info",
            40,
            {},
            target_date,
        )
        return

    insert_insight(
        user_id,
        "project",
        "projects",
        "Project progress overview",
        f"You currently have {active_projects} active project(s). Your average progress is {avg_progress:.1f}%.",
        "info",
        avg_progress,
        metrics,
        target_date,
    )

    if overdue_projects > 0:
        insert_alert(
            user_id,
            "project_overdue",
            "projects",
            "Overdue project detected",
            f"You have {overdue_projects} overdue project(s). Review deadlines and update milestones.",
            "critical",
            85,
            metrics,
            target_date,
        )


def create_daily_summary(user_id, target_date):
    insights = fetch_all(
        """
        SELECT severity, COUNT(*) AS count
        FROM ai_insights
        WHERE user_id = %(user_id)s
        AND insight_date = %(target_date)s
        GROUP BY severity
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )

    alerts = fetch_one(
        """
        SELECT COUNT(*) AS count
        FROM ai_alerts
        WHERE user_id = %(user_id)s
        AND alert_date = %(target_date)s
        AND is_resolved = false
        """,
        {
            "user_id": user_id,
            "target_date": target_date,
        },
    )

    alert_count = alerts["count"] if alerts else 0

    severity_map = {row["severity"]: row["count"] for row in insights}

    success_count = severity_map.get("success", 0)
    warning_count = severity_map.get("warning", 0)
    critical_count = severity_map.get("critical", 0)

    if critical_count > 0:
        severity = "critical"
        score = 55
    elif warning_count > 0 or alert_count > 0:
        severity = "warning"
        score = 70
    elif success_count > 0:
        severity = "success"
        score = 85
    else:
        severity = "info"
        score = 60

    insert_insight(
        user_id,
        "daily_summary",
        "unified",
        "Daily AI summary",
        f"Today you have {success_count} positive insight(s), {warning_count} warning(s), and {alert_count} active alert(s).",
        severity,
        score,
        {
            "success_count": success_count,
            "warning_count": warning_count,
            "critical_count": critical_count,
            "alert_count": alert_count,
        },
        target_date,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-id", required=True)
    parser.add_argument("--date", required=False, default=str(date.today()))
    args = parser.parse_args()

    user_id = args.user_id
    target_date = args.date

    clear_existing_daily_data(user_id, target_date)

    analyze_finance(user_id, target_date)
    analyze_health(user_id, target_date)
    analyze_projects(user_id, target_date)
    create_daily_summary(user_id, target_date)

    print(f"Daily AI insights generated successfully for user {user_id} on {target_date}")


if __name__ == "__main__":
    main()
