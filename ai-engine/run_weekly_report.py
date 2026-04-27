import argparse
import json
import uuid
from datetime import date, timedelta
from decimal import Decimal

from db import fetch_one, execute


def decimal_to_float(value):
    if isinstance(value, Decimal):
        return float(value)
    return value


def get_week_range():
    today = date.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    return start, end


def get_finance_week(user_id, start_date, end_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) AS income_total,
            COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) AS expense_total,
            COUNT(*) AS transaction_count
        FROM nix_life_os.finance_transaction
        WHERE user_id = %(user_id)s
        AND transaction_date::date BETWEEN %(start_date)s AND %(end_date)s
        """,
        {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
        },
    )


def get_health_week(user_id, start_date, end_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(amount_ml), 0) AS total_water_ml,
            COUNT(DISTINCT log_date::date) AS hydration_days
        FROM health_hydration_logs
        WHERE user_id = %(user_id)s
        AND log_date::date BETWEEN %(start_date)s AND %(end_date)s
        """,
        {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
        },
    )


def get_steps_week(user_id, start_date, end_date):
    return fetch_one(
        """
        SELECT
            COALESCE(SUM(steps_count), 0) AS total_steps,
            COALESCE(AVG(steps_count), 0) AS avg_steps
        FROM health_step_log
        WHERE user_id = %(user_id)s
        AND log_date::date BETWEEN %(start_date)s AND %(end_date)s
        """,
        {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
        },
    )


def get_projects_summary(user_id):
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


def calculate_score(finance, health, steps, projects):
    score = 70

    income = decimal_to_float(finance["income_total"])
    expenses = decimal_to_float(finance["expense_total"])
    net = income - expenses

    if net > 0:
        score += 10
    elif net < 0:
        score -= 10

    hydration_days = int(health["hydration_days"])
    if hydration_days >= 5:
        score += 5
    elif hydration_days <= 2:
        score -= 5

    avg_steps = decimal_to_float(steps["avg_steps"])
    if avg_steps >= 5000:
        score += 5
    elif avg_steps < 2000:
        score -= 5

    overdue_projects = int(projects["overdue_projects"])
    if overdue_projects > 0:
        score -= 10

    return max(0, min(score, 100))


def build_recommendations(finance, health, steps, projects):
    recommendations = []

    income = decimal_to_float(finance["income_total"])
    expenses = decimal_to_float(finance["expense_total"])
    net = income - expenses

    if net < 0:
        recommendations.append({
            "module": "finance",
            "title": "Reduce weekly expenses",
            "message": "Your weekly expenses exceeded your income. Review spending categories and reduce non-essential expenses."
        })
    elif net > 0:
        recommendations.append({
            "module": "finance",
            "title": "Increase savings allocation",
            "message": "You had positive weekly cash flow. Consider moving part of it to your savings account."
        })

    hydration_days = int(health["hydration_days"])
    if hydration_days < 5:
        recommendations.append({
            "module": "health",
            "title": "Improve hydration tracking consistency",
            "message": "You did not log hydration consistently this week. Track your fluids daily according to your doctor-approved target."
        })

    avg_steps = decimal_to_float(steps["avg_steps"])
    if avg_steps < 3000:
        recommendations.append({
            "module": "health",
            "title": "Add light daily movement",
            "message": "Your average step count was low this week. Consider short, gentle walks if you feel well."
        })

    overdue_projects = int(projects["overdue_projects"])
    if overdue_projects > 0:
        recommendations.append({
            "module": "projects",
            "title": "Review overdue projects",
            "message": "Some projects are overdue. Update deadlines, milestones, or priorities."
        })

    return recommendations


def insert_report(user_id, start_date, end_date, finance, health, steps, projects, recommendations, score):
    execute(
        """
        DELETE FROM ai_reports
        WHERE user_id = %(user_id)s
        AND report_type = 'weekly'
        AND period_start = %(period_start)s
        AND period_end = %(period_end)s
        """,
        {
            "user_id": user_id,
            "period_start": start_date,
            "period_end": end_date,
        },
    )

    income = decimal_to_float(finance["income_total"])
    expenses = decimal_to_float(finance["expense_total"])
    net = income - expenses

    summary = (
        f"This week your income was {income:.2f}, expenses were {expenses:.2f}, "
        f"and net cash flow was {net:.2f}. "
        f"You logged hydration on {int(health['hydration_days'])} day(s), "
        f"with an average of {decimal_to_float(steps['avg_steps']):.0f} steps. "
        f"Your project average progress is {decimal_to_float(projects['avg_progress']):.1f}%."
    )

    execute(
        """
        INSERT INTO ai_reports (
            id,
            user_id,
            report_type,
            period_start,
            period_end,
            title,
            summary,
            finance_summary,
            health_summary,
            project_summary,
            recommendations,
            raw_metrics,
            overall_score,
            created_at,
            updated_at
        )
        VALUES (
            %(id)s,
            %(user_id)s,
            'weekly',
            %(period_start)s,
            %(period_end)s,
            %(title)s,
            %(summary)s,
            %(finance_summary)s::jsonb,
            %(health_summary)s::jsonb,
            %(project_summary)s::jsonb,
            %(recommendations)s::jsonb,
            %(raw_metrics)s::jsonb,
            %(overall_score)s,
            NOW(),
            NOW()
        )
        """,
        {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "period_start": start_date,
            "period_end": end_date,
            "title": f"Weekly AI Report: {start_date} to {end_date}",
            "summary": summary,
            "finance_summary": json.dumps({
                "income_total": income,
                "expense_total": expenses,
                "net_cashflow": net,
                "transaction_count": int(finance["transaction_count"]),
            }),
            "health_summary": json.dumps({
                "total_water_ml": decimal_to_float(health["total_water_ml"]),
                "hydration_days": int(health["hydration_days"]),
                "total_steps": int(steps["total_steps"]),
                "avg_steps": decimal_to_float(steps["avg_steps"]),
            }),
            "project_summary": json.dumps({
                "total_projects": int(projects["total_projects"]),
                "active_projects": int(projects["active_projects"]),
                "completed_projects": int(projects["completed_projects"]),
                "overdue_projects": int(projects["overdue_projects"]),
                "avg_progress": decimal_to_float(projects["avg_progress"]),
            }),
            "recommendations": json.dumps(recommendations),
            "raw_metrics": json.dumps({
                "finance": dict(finance),
                "health": dict(health),
                "steps": dict(steps),
                "projects": dict(projects),
            }, default=str),
            "overall_score": score,
        },
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-id", required=True)
    args = parser.parse_args()

    user_id = args.user_id

    start_date, end_date = get_week_range()

    finance = get_finance_week(user_id, start_date, end_date)
    health = get_health_week(user_id, start_date, end_date)
    steps = get_steps_week(user_id, start_date, end_date)
    projects = get_projects_summary(user_id)

    score = calculate_score(finance, health, steps, projects)
    recommendations = build_recommendations(finance, health, steps, projects)

    insert_report(
        user_id,
        start_date,
        end_date,
        finance,
        health,
        steps,
        projects,
        recommendations,
        score,
    )

    print(f"Weekly AI report generated successfully for user {user_id} from {start_date} to {end_date}")


if __name__ == "__main__":
    main()
