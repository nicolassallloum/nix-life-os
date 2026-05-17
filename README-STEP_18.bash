🔹 STEP 18 — AI Insights Engine
1. What This Step Will Add

You will build:

Daily Insights
Weekly Reports
Smart Alerts
Python Analytics Engine
Laravel Backend Integration
PostgreSQL Storage
API Endpoints
Scheduled Commands

This step does not need advanced OpenAI integration yet. We will build a strong local rule-based AI engine first.

Later, we can add:

OpenAI / local LLM summaries
Predictive analytics
Natural language recommendations
Chat assistant inside NIX LIFE OS
2. Backend Database Tables

Go to backend:

cd /u01/nix-life-os/backend

Create migrations:

php artisan make:migration create_ai_insights_table
php artisan make:migration create_ai_alerts_table
php artisan make:migration create_ai_reports_table
File 1 — database/migrations/xxxx_xx_xx_create_ai_insights_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_insights', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('insight_type', 50)->index();
            // daily_summary, finance, health, project, productivity, recommendation

            $table->string('category', 100)->nullable()->index();
            // finance, health, projects, unified

            $table->string('title');
            $table->text('message');

            $table->string('severity', 30)->default('info')->index();
            // info, success, warning, critical

            $table->decimal('score', 8, 2)->nullable();
            $table->jsonb('metadata')->nullable();

            $table->date('insight_date')->index();

            $table->boolean('is_read')->default(false);
            $table->boolean('is_archived')->default(false);

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'insight_date']);
            $table->index(['user_id', 'severity']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_insights');
    }
};
File 2 — database/migrations/xxxx_xx_xx_create_ai_alerts_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_alerts', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('alert_type', 80)->index();
            // budget_risk, health_warning, project_delay, hydration_low, spending_spike

            $table->string('module', 50)->index();
            // finance, health, projects, unified

            $table->string('title');
            $table->text('message');

            $table->string('severity', 30)->default('warning')->index();
            // info, warning, critical

            $table->decimal('risk_score', 8, 2)->nullable();

            $table->jsonb('trigger_data')->nullable();

            $table->date('alert_date')->index();

            $table->boolean('is_resolved')->default(false);
            $table->timestamp('resolved_at')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'alert_date']);
            $table->index(['user_id', 'is_resolved']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_alerts');
    }
};
File 3 — database/migrations/xxxx_xx_xx_create_ai_reports_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_reports', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('report_type', 50)->index();
            // daily, weekly, monthly

            $table->date('period_start')->index();
            $table->date('period_end')->index();

            $table->string('title');
            $table->text('summary')->nullable();

            $table->jsonb('finance_summary')->nullable();
            $table->jsonb('health_summary')->nullable();
            $table->jsonb('project_summary')->nullable();
            $table->jsonb('recommendations')->nullable();
            $table->jsonb('raw_metrics')->nullable();

            $table->decimal('overall_score', 8, 2)->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'report_type']);
            $table->index(['user_id', 'period_start', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_reports');
    }
};

Run migration:

php artisan migrate
3. Laravel Models

Create models:

php artisan make:model AiInsight
php artisan make:model AiAlert
php artisan make:model AiReport
File 4 — app/Models/AiInsight.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiInsight extends Model
{
    use HasUuids;

    protected $table = 'ai_insights';

    protected $fillable = [
        'user_id',
        'insight_type',
        'category',
        'title',
        'message',
        'severity',
        'score',
        'metadata',
        'insight_date',
        'is_read',
        'is_archived',
    ];

    protected $casts = [
        'metadata' => 'array',
        'insight_date' => 'date',
        'is_read' => 'boolean',
        'is_archived' => 'boolean',
        'score' => 'decimal:2',
    ];
}
File 5 — app/Models/AiAlert.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiAlert extends Model
{
    use HasUuids;

    protected $table = 'ai_alerts';

    protected $fillable = [
        'user_id',
        'alert_type',
        'module',
        'title',
        'message',
        'severity',
        'risk_score',
        'trigger_data',
        'alert_date',
        'is_resolved',
        'resolved_at',
    ];

    protected $casts = [
        'trigger_data' => 'array',
        'alert_date' => 'date',
        'resolved_at' => 'datetime',
        'is_resolved' => 'boolean',
        'risk_score' => 'decimal:2',
    ];
}
File 6 — app/Models/AiReport.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiReport extends Model
{
    use HasUuids;

    protected $table = 'ai_reports';

    protected $fillable = [
        'user_id',
        'report_type',
        'period_start',
        'period_end',
        'title',
        'summary',
        'finance_summary',
        'health_summary',
        'project_summary',
        'recommendations',
        'raw_metrics',
        'overall_score',
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'finance_summary' => 'array',
        'health_summary' => 'array',
        'project_summary' => 'array',
        'recommendations' => 'array',
        'raw_metrics' => 'array',
        'overall_score' => 'decimal:2',
    ];
}
4. Laravel AI Controller

Create controller:

php artisan make:controller Api/V1/AiInsightController
File 7 — app/Http/Controllers/Api/V1/AiInsightController.php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiAlert;
use App\Models\AiInsight;
use App\Models\AiReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Process;

class AiInsightController extends Controller
{
    public function daily(Request $request)
    {
        $user = $request->user();

        $date = $request->query('date', now()->toDateString());

        $insights = AiInsight::query()
            ->where('user_id', $user->id)
            ->whereDate('insight_date', $date)
            ->where('is_archived', false)
            ->orderByRaw("
                CASE severity
                    WHEN 'critical' THEN 1
                    WHEN 'warning' THEN 2
                    WHEN 'success' THEN 3
                    ELSE 4
                END
            ")
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daily AI insights retrieved successfully.',
            'data' => $insights,
        ]);
    }

    public function alerts(Request $request)
    {
        $user = $request->user();

        $alerts = AiAlert::query()
            ->where('user_id', $user->id)
            ->when(!$request->boolean('include_resolved'), function ($query) {
                $query->where('is_resolved', false);
            })
            ->orderByRaw("
                CASE severity
                    WHEN 'critical' THEN 1
                    WHEN 'warning' THEN 2
                    ELSE 3
                END
            ")
            ->latest()
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'AI alerts retrieved successfully.',
            'data' => $alerts,
        ]);
    }

    public function weeklyReport(Request $request)
    {
        $user = $request->user();

        $report = AiReport::query()
            ->where('user_id', $user->id)
            ->where('report_type', 'weekly')
            ->latest('period_end')
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Weekly AI report retrieved successfully.',
            'data' => $report,
        ]);
    }

    public function reports(Request $request)
    {
        $user = $request->user();

        $reports = AiReport::query()
            ->where('user_id', $user->id)
            ->when($request->query('type'), function ($query, $type) {
                $query->where('report_type', $type);
            })
            ->latest('period_end')
            ->paginate(10);

        return response()->json([
            'success' => true,
            'message' => 'AI reports retrieved successfully.',
            'data' => $reports,
        ]);
    }

    public function markInsightRead(Request $request, string $id)
    {
        $user = $request->user();

        $insight = AiInsight::where('user_id', $user->id)->findOrFail($id);

        $insight->update([
            'is_read' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Insight marked as read.',
            'data' => $insight,
        ]);
    }

    public function resolveAlert(Request $request, string $id)
    {
        $user = $request->user();

        $alert = AiAlert::where('user_id', $user->id)->findOrFail($id);

        $alert->update([
            'is_resolved' => true,
            'resolved_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Alert resolved successfully.',
            'data' => $alert,
        ]);
    }

    public function runDailyEngine(Request $request)
    {
        $user = $request->user();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_daily_insights.py');

        $result = Process::timeout(120)->run([
            $pythonPath,
            $scriptPath,
            '--user-id=' . $user->id,
            '--date=' . now()->toDateString(),
        ]);

        if (!$result->successful()) {
            return response()->json([
                'success' => false,
                'message' => 'AI engine failed.',
                'error' => $result->errorOutput(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Daily AI engine executed successfully.',
            'output' => $result->output(),
        ]);
    }

    public function runWeeklyEngine(Request $request)
    {
        $user = $request->user();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_weekly_report.py');

        $result = Process::timeout(180)->run([
            $pythonPath,
            $scriptPath,
            '--user-id=' . $user->id,
        ]);

        if (!$result->successful()) {
            return response()->json([
                'success' => false,
                'message' => 'Weekly AI engine failed.',
                'error' => $result->errorOutput(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Weekly AI report generated successfully.',
            'output' => $result->output(),
        ]);
    }
}
5. Add API Routes

Open:

nano routes/api.php

Inside your authenticated /api/v1 group, add this:

use App\Http\Controllers\Api\V1\AiInsightController;

Then add routes:

Route::prefix('ai')->group(function () {
    Route::get('/insights/daily', [AiInsightController::class, 'daily']);
    Route::get('/alerts', [AiInsightController::class, 'alerts']);
    Route::get('/reports', [AiInsightController::class, 'reports']);
    Route::get('/reports/weekly', [AiInsightController::class, 'weeklyReport']);

    Route::patch('/insights/{id}/read', [AiInsightController::class, 'markInsightRead']);
    Route::patch('/alerts/{id}/resolve', [AiInsightController::class, 'resolveAlert']);

    Route::post('/engine/daily/run', [AiInsightController::class, 'runDailyEngine']);
    Route::post('/engine/weekly/run', [AiInsightController::class, 'runWeeklyEngine']);
});

Example full placement:

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {

    // Existing Finance, Health, Projects, Dashboard routes...

    Route::prefix('ai')->group(function () {
        Route::get('/insights/daily', [AiInsightController::class, 'daily']);
        Route::get('/alerts', [AiInsightController::class, 'alerts']);
        Route::get('/reports', [AiInsightController::class, 'reports']);
        Route::get('/reports/weekly', [AiInsightController::class, 'weeklyReport']);

        Route::patch('/insights/{id}/read', [AiInsightController::class, 'markInsightRead']);
        Route::patch('/alerts/{id}/resolve', [AiInsightController::class, 'resolveAlert']);

        Route::post('/engine/daily/run', [AiInsightController::class, 'runDailyEngine']);
        Route::post('/engine/weekly/run', [AiInsightController::class, 'runWeeklyEngine']);
    });

});

Then run:

php artisan optimize:clear
php artisan route:list | grep ai

Expected routes:

GET      api/v1/ai/insights/daily
GET      api/v1/ai/alerts
GET      api/v1/ai/reports
GET      api/v1/ai/reports/weekly
PATCH    api/v1/ai/insights/{id}/read
PATCH    api/v1/ai/alerts/{id}/resolve
POST     api/v1/ai/engine/daily/run
POST     api/v1/ai/engine/weekly/run
6. Python AI Engine Folder

From project root:

cd /u01/nix-life-os
mkdir -p ai-engine
cd ai-engine

Create virtual environment:

python3 -m venv venv
source venv/bin/activate

Install packages:

pip install psycopg2-binary python-dotenv pandas

Create .env:

nano .env

Add:

DB_HOST=127.0.0.1
DB_PORT=5445
DB_NAME=nixlifeos_db
DB_USER=postgres
DB_PASSWORD=your_password_here

Replace your_password_here with your real PostgreSQL password.

7. Python Database Helper

Create:

nano db.py
File 8 — /u01/nix-life-os/ai-engine/db.py
import os
import psycopg2
from dotenv import load_dotenv
from psycopg2.extras import RealDictCursor

load_dotenv()


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=os.getenv("DB_PORT", "5445"),
        database=os.getenv("DB_NAME", "nixlifeos_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", ""),
        cursor_factory=RealDictCursor,
    )


def fetch_one(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params or {})
            return cur.fetchone()
    finally:
        conn.close()


def fetch_all(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params or {})
            return cur.fetchall()
    finally:
        conn.close()


def execute(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params or {})
        conn.commit()
    finally:
        conn.close()
8. Daily AI Insights Script

Create:

nano run_daily_insights.py
File 9 — /u01/nix-life-os/ai-engine/run_daily_insights.py
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
            "metadata": json.dumps(metadata or {}),
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
            "trigger_data": json.dumps(trigger_data or {}),
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
        FROM finance_transactions
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
            COALESCE(SUM(water_ml), 0) AS water_ml,
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
        FROM health_step_logs
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
9. Weekly Report Script

Create:

nano run_weekly_report.py
File 10 — /u01/nix-life-os/ai-engine/run_weekly_report.py
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
        FROM finance_transactions
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
            COALESCE(SUM(water_ml), 0) AS total_water_ml,
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
        FROM health_step_logs
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
10. Important: Check Your Table Names

The scripts assume these table names:

finance_transactions
health_hydration_logs
health_weight_logs
health_step_logs
projects
users

Check your real table names:

php artisan tinker

Then:

Schema::hasTable('finance_transactions');
Schema::hasTable('health_hydration_logs');
Schema::hasTable('health_weight_logs');
Schema::hasTable('health_step_logs');
Schema::hasTable('projects');

If one returns false, check with PostgreSQL:

psql -U postgres -d nixlifeos_db

Then:

\dt

If your actual table names are different, update them in the Python scripts.

11. Test Python Engine Manually

First get your user ID.

In Laravel:

php artisan tinker
App\Models\User::first();

Copy the user id.

Then run:

cd /u01/nix-life-os/ai-engine
source venv/bin/activate

python run_daily_insights.py --user-id=YOUR_USER_ID --date=2026-04-27

Example:

python run_daily_insights.py --user-id=019dc843-0000-7000-b000-000000000001 --date=2026-04-27

Run weekly:

python run_weekly_report.py --user-id=YOUR_USER_ID

Check data in PostgreSQL:

SELECT * FROM ai_insights ORDER BY created_at DESC;
SELECT * FROM ai_alerts ORDER BY created_at DESC;
SELECT * FROM ai_reports ORDER BY created_at DESC;
12. Test Laravel API

Use your token:

TOKEN="YOUR_TOKEN_HERE"

Run daily engine through Laravel:

curl -X POST http://127.0.0.1:8000/api/v1/ai/engine/daily/run \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Get daily insights:

curl http://127.0.0.1:8000/api/v1/ai/insights/daily \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Get alerts:

curl http://127.0.0.1:8000/api/v1/ai/alerts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Run weekly engine:

curl -X POST http://127.0.0.1:8000/api/v1/ai/engine/weekly/run \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Get weekly report:

curl http://127.0.0.1:8000/api/v1/ai/reports/weekly \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
13. Laravel Artisan Commands

Now create backend commands so the engine can run from scheduler.

php artisan make:command RunDailyAiInsights
php artisan make:command RunWeeklyAiReport
File 11 — app/Console/Commands/RunDailyAiInsights.php
<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Process;

class RunDailyAiInsights extends Command
{
    protected $signature = 'ai:daily-insights {--user_id=} {--date=}';

    protected $description = 'Run daily AI insights engine for one user or all users';

    public function handle(): int
    {
        $userId = $this->option('user_id');
        $date = $this->option('date') ?: now()->toDateString();

        $users = User::query()
            ->when($userId, function ($query) use ($userId) {
                $query->where('id', $userId);
            })
            ->get();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_daily_insights.py');

        foreach ($users as $user) {
            $this->info("Running daily AI insights for user {$user->id}");

            $result = Process::timeout(120)->run([
                $pythonPath,
                $scriptPath,
                '--user-id=' . $user->id,
                '--date=' . $date,
            ]);

            if (!$result->successful()) {
                $this->error($result->errorOutput());
                continue;
            }

            $this->info($result->output());
        }

        return self::SUCCESS;
    }
}
File 12 — app/Console/Commands/RunWeeklyAiReport.php
<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Process;

class RunWeeklyAiReport extends Command
{
    protected $signature = 'ai:weekly-report {--user_id=}';

    protected $description = 'Run weekly AI report engine for one user or all users';

    public function handle(): int
    {
        $userId = $this->option('user_id');

        $users = User::query()
            ->when($userId, function ($query) use ($userId) {
                $query->where('id', $userId);
            })
            ->get();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_weekly_report.py');

        foreach ($users as $user) {
            $this->info("Running weekly AI report for user {$user->id}");

            $result = Process::timeout(180)->run([
                $pythonPath,
                $scriptPath,
                '--user-id=' . $user->id,
            ]);

            if (!$result->successful()) {
                $this->error($result->errorOutput());
                continue;
            }

            $this->info($result->output());
        }

        return self::SUCCESS;
    }
}
14. Test Artisan Commands
php artisan ai:daily-insights

For one user:

php artisan ai:daily-insights --user_id=YOUR_USER_ID

For specific date:

php artisan ai:daily-insights --user_id=YOUR_USER_ID --date=2026-04-27

Weekly:

php artisan ai:weekly-report

For one user:

php artisan ai:weekly-report --user_id=YOUR_USER_ID
15. Laravel Scheduler

Open:

nano routes/console.php

Add:

use Illuminate\Support\Facades\Schedule;

Schedule::command('ai:daily-insights')
    ->dailyAt('23:55');

Schedule::command('ai:weekly-report')
    ->weeklyOn(7, '23:30');

Test scheduler:

php artisan schedule:list

Expected:

ai:daily-insights
ai:weekly-report
16. Cron Job

Open crontab:

crontab -e

Add:

* * * * * cd /u01/nix-life-os/backend && php artisan schedule:run >> /dev/null 2>&1
17. Smart Alert Rules Added

This engine currently detects:

Finance:
- Negative daily cash flow
- High expense ratio
- No finance activity

Health:
- No hydration tracking
- Low hydration tracking
- Step count performance
- Latest weight reminder

Projects:
- Average project progress
- Overdue projects

Unified:
- Daily summary
- Weekly score
- Recommendations
18. Common Error Fixes
Error: Class "Process" not found

Laravel Process exists in modern Laravel versions.

If it fails, replace:

use Illuminate\Support\Facades\Process;

With native PHP:

$output = shell_exec("cd " . base_path('../ai-engine') . " && venv/bin/python run_daily_insights.py --user-id={$user->id}");

But Process is cleaner.

Error: Python file not found

Check paths:

ls -lah /u01/nix-life-os/ai-engine
ls -lah /u01/nix-life-os/ai-engine/venv/bin/python
Error: PostgreSQL connection failed

Check .env:

cat /u01/nix-life-os/ai-engine/.env

Test connection:

cd /u01/nix-life-os/ai-engine
source venv/bin/activate
python

Then:

from db import fetch_one
print(fetch_one("SELECT NOW()"))
Error: table does not exist

Check table names:

\dt

Then update the Python SQL queries with the correct table names.

19. Step 18 Completion Checklist

After this step, you should have:

✅ ai_insights table
✅ ai_alerts table
✅ ai_reports table
✅ AiInsight model
✅ AiAlert model
✅ AiReport model
✅ AiInsightController
✅ AI API routes
✅ Python ai-engine folder
✅ Daily insights Python script
✅ Weekly report Python script
✅ Laravel artisan commands
✅ Laravel scheduler
✅ Cron support
✅ API tested with curl
20. Final API Summary
GET    /api/v1/ai/insights/daily
GET    /api/v1/ai/alerts
GET    /api/v1/ai/reports
GET    /api/v1/ai/reports/weekly

PATCH  /api/v1/ai/insights/{id}/read
PATCH  /api/v1/ai/alerts/{id}/resolve

POST   /api/v1/ai/engine/daily/run
POST   /api/v1/ai/engine/weekly/run
21. Step 19 Recommendation

After Step 18, the best next step is:

🔹 STEP 19 — AI Insights Frontend UI

Build:
- AI Insights dashboard cards
- Daily insight feed
- Smart alert panel
- Weekly report page
- Severity colors
- Resolve alert button
- Mark insight as read
- Run AI engine button

This will connect the new AI backend to your Vue dashboard.