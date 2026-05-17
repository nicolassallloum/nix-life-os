🔹 STEP 19 — Prediction Models
NIX LIFE OS — Weight Prediction + Financial Forecast
This step adds predictive intelligence to NIX LIFE OS using your existing stack:
Backend: LaravelDatabase: PostgreSQLAI Engine: PythonFrontend: Vue later
You will build two prediction models:
1. Weight Prediction Model   Predict future body weight based on weight logs.2. Financial Forecast Model   Predict income, expenses, savings, and end-of-month balance.

1. Prediction Logic Overview
A. Weight Prediction Formula
For the first version, use linear trend prediction.
y^=mx+b\hat{y}=mx+by^​=mx+b
Where:
ŷ = predicted weightx = day numberm = average daily weight changeb = starting/base weight
Simple model:
Predicted Weight = Latest Weight + (Average Daily Change × Days Ahead)
Example:
Latest weight = 64 kgAverage daily change = -0.05 kg/dayPredict 30 days ahead:64 + (-0.05 × 30) = 62.5 kg

B. Financial Forecast Formula
For financial forecast:
Net Cash Flow = Total Income - Total Expenses
Forecast Balance=Current Balance+(Average Daily Net Cash Flow×Days Remaining)\text{Forecast Balance}=\text{Current Balance}+\left(\text{Average Daily Net Cash Flow}\times\text{Days Remaining}\right)Forecast Balance=Current Balance+(Average Daily Net Cash Flow×Days Remaining)
Simple model:
Forecast Balance =Current Balance + Average Daily Net Cash Flow × Remaining Days
Example:
Current balance = $1,000Average daily income = $50Average daily expenses = $30Average daily net = $20Remaining days = 10Forecast balance = 1000 + (20 × 10) = 1200

2. Backend Database Design
Create a table to store prediction results.
Create Migration
From backend folder:
cd /u01/nix-life-os/backendphp artisan make:migration create_ai_predictions_table
Open the created file:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_ai_predictions_table.php
Replace with:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('ai_predictions', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->string('prediction_type');            // weight_prediction            // financial_forecast            $table->date('prediction_date');            $table->date('target_date')->nullable();            $table->decimal('current_value', 14, 2)->nullable();            $table->decimal('predicted_value', 14, 2)->nullable();            $table->decimal('change_value', 14, 2)->nullable();            $table->decimal('change_percentage', 8, 2)->nullable();            $table->jsonb('input_summary')->nullable();            $table->jsonb('prediction_payload')->nullable();            $table->string('confidence_level')->default('medium');            // low, medium, high            $table->text('notes')->nullable();            $table->timestamps();            $table->index(['user_id', 'prediction_type']);            $table->index(['prediction_date']);            $table->index(['target_date']);        });    }    public function down(): void    {        Schema::dropIfExists('ai_predictions');    }};
Run migration:
php artisan migrate

3. Laravel Model
Create model:
php artisan make:model AiPrediction
Open:
nano app/Models/AiPrediction.php
Add:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Concerns\HasUuids;class AiPrediction extends Model{    use HasUuids;    protected $table = 'ai_predictions';    protected $fillable = [        'user_id',        'prediction_type',        'prediction_date',        'target_date',        'current_value',        'predicted_value',        'change_value',        'change_percentage',        'input_summary',        'prediction_payload',        'confidence_level',        'notes',    ];    protected $casts = [        'prediction_date' => 'date',        'target_date' => 'date',        'current_value' => 'decimal:2',        'predicted_value' => 'decimal:2',        'change_value' => 'decimal:2',        'change_percentage' => 'decimal:2',        'input_summary' => 'array',        'prediction_payload' => 'array',    ];}

4. Python AI Engine Structure
Go to your AI engine:
cd /u01/nix-life-os/ai-engine
Create folders:
mkdir -p predictionstouch predictions/__init__.py
Final structure:
ai-engine/├── predictions/│   ├── __init__.py│   ├── weight_prediction.py│   └── financial_forecast.py├── run_daily_insights.py

5. Weight Prediction Model
Create file:
nano predictions/weight_prediction.py
Add:
from datetime import datetime, timedeltafrom decimal import Decimalimport psycopg2import psycopg2.extrasimport osDB_HOST = os.getenv("DB_HOST", "127.0.0.1")DB_PORT = os.getenv("DB_PORT", "5445")DB_NAME = os.getenv("DB_DATABASE", "nixlifeos_db")DB_USER = os.getenv("DB_USERNAME", "postgres")DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")def get_connection():    return psycopg2.connect(        host=DB_HOST,        port=DB_PORT,        database=DB_NAME,        user=DB_USER,        password=DB_PASSWORD    )def calculate_weight_prediction(user_id: str, days_ahead: int = 30):    """    Predict user weight using simple linear average daily change.    """    conn = get_connection()    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)    cur.execute("""        SELECT            log_date,            weight_kg        FROM health_weight_logs        WHERE user_id = %s        ORDER BY log_date ASC    """, (user_id,))    rows = cur.fetchall()    if len(rows) < 2:        cur.close()        conn.close()        return {            "status": "insufficient_data",            "message": "At least 2 weight logs are required for prediction.",            "user_id": user_id        }    first_log = rows[0]    latest_log = rows[-1]    first_date = first_log["log_date"]    latest_date = latest_log["log_date"]    first_weight = float(first_log["weight_kg"])    latest_weight = float(latest_log["weight_kg"])    days_between = (latest_date - first_date).days    if days_between <= 0:        average_daily_change = 0    else:        average_daily_change = (latest_weight - first_weight) / days_between    predicted_weight = latest_weight + (average_daily_change * days_ahead)    target_date = latest_date + timedelta(days=days_ahead)    change_value = predicted_weight - latest_weight    if latest_weight > 0:        change_percentage = (change_value / latest_weight) * 100    else:        change_percentage = 0    confidence_level = "medium"    if len(rows) >= 10:        confidence_level = "high"    elif len(rows) < 5:        confidence_level = "low"    result = {        "status": "success",        "user_id": user_id,        "prediction_type": "weight_prediction",        "prediction_date": datetime.now().date().isoformat(),        "target_date": target_date.isoformat(),        "current_weight": round(latest_weight, 2),        "predicted_weight": round(predicted_weight, 2),        "change_value": round(change_value, 2),        "change_percentage": round(change_percentage, 2),        "average_daily_change": round(average_daily_change, 4),        "days_ahead": days_ahead,        "logs_count": len(rows),        "confidence_level": confidence_level,        "input_summary": {            "first_date": first_date.isoformat(),            "first_weight": first_weight,            "latest_date": latest_date.isoformat(),            "latest_weight": latest_weight,            "days_between": days_between        }    }    cur.execute("""        INSERT INTO ai_predictions (            id,            user_id,            prediction_type,            prediction_date,            target_date,            current_value,            predicted_value,            change_value,            change_percentage,            input_summary,            prediction_payload,            confidence_level,            notes,            created_at,            updated_at        )        VALUES (            gen_random_uuid(),            %s,            %s,            %s,            %s,            %s,            %s,            %s,            %s,            %s::jsonb,            %s::jsonb,            %s,            %s,            NOW(),            NOW()        )    """, (        user_id,        "weight_prediction",        result["prediction_date"],        result["target_date"],        result["current_weight"],        result["predicted_weight"],        result["change_value"],        result["change_percentage"],        psycopg2.extras.Json(result["input_summary"]),        psycopg2.extras.Json(result),        confidence_level,        "Weight prediction generated using linear average daily change."    ))    conn.commit()    cur.close()    conn.close()    return result

6. Financial Forecast Model
Create file:
nano predictions/financial_forecast.py
Add:
from datetime import datetime, dateimport calendarimport psycopg2import psycopg2.extrasimport osDB_HOST = os.getenv("DB_HOST", "127.0.0.1")DB_PORT = os.getenv("DB_PORT", "5445")DB_NAME = os.getenv("DB_DATABASE", "nixlifeos_db")DB_USER = os.getenv("DB_USERNAME", "postgres")DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")def get_connection():    return psycopg2.connect(        host=DB_HOST,        port=DB_PORT,        database=DB_NAME,        user=DB_USER,        password=DB_PASSWORD    )def calculate_financial_forecast(user_id: str, target_month: str = None):    """    Forecast monthly finance using current month income/expenses.    target_month format: YYYY-MM    """    today = date.today()    if target_month:        year, month = map(int, target_month.split("-"))    else:        year = today.year        month = today.month    first_day = date(year, month, 1)    last_day = date(year, month, calendar.monthrange(year, month)[1])    if today.year == year and today.month == month:        elapsed_days = today.day        remaining_days = (last_day - today).days    else:        elapsed_days = (last_day - first_day).days + 1        remaining_days = 0    conn = get_connection()    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)    # Current total balance    cur.execute("""        SELECT            COALESCE(SUM(current_balance), 0) AS total_balance        FROM finance_accounts        WHERE user_id = %s    """, (user_id,))    balance_row = cur.fetchone()    current_balance = float(balance_row["total_balance"] or 0)    # Income and expenses for current month    cur.execute("""        SELECT            COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) AS total_income,            COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) AS total_expenses        FROM finance_transactions        WHERE user_id = %s          AND transaction_date BETWEEN %s AND %s    """, (user_id, first_day, today))    tx_row = cur.fetchone()    total_income = float(tx_row["total_income"] or 0)    total_expenses = float(tx_row["total_expenses"] or 0)    net_cash_flow = total_income - total_expenses    if elapsed_days <= 0:        average_daily_income = 0        average_daily_expenses = 0        average_daily_net = 0    else:        average_daily_income = total_income / elapsed_days        average_daily_expenses = total_expenses / elapsed_days        average_daily_net = net_cash_flow / elapsed_days    forecast_income = total_income + (average_daily_income * remaining_days)    forecast_expenses = total_expenses + (average_daily_expenses * remaining_days)    forecast_net_cash_flow = forecast_income - forecast_expenses    forecast_balance = current_balance + (average_daily_net * remaining_days)    if current_balance > 0:        change_percentage = ((forecast_balance - current_balance) / current_balance) * 100    else:        change_percentage = 0    confidence_level = "medium"    if elapsed_days >= 20:        confidence_level = "high"    elif elapsed_days < 7:        confidence_level = "low"    result = {        "status": "success",        "user_id": user_id,        "prediction_type": "financial_forecast",        "prediction_date": today.isoformat(),        "target_date": last_day.isoformat(),        "month": f"{year}-{str(month).zfill(2)}",        "current_balance": round(current_balance, 2),        "total_income_so_far": round(total_income, 2),        "total_expenses_so_far": round(total_expenses, 2),        "net_cash_flow_so_far": round(net_cash_flow, 2),        "average_daily_income": round(average_daily_income, 2),        "average_daily_expenses": round(average_daily_expenses, 2),        "average_daily_net": round(average_daily_net, 2),        "forecast_income": round(forecast_income, 2),        "forecast_expenses": round(forecast_expenses, 2),        "forecast_net_cash_flow": round(forecast_net_cash_flow, 2),        "forecast_balance": round(forecast_balance, 2),        "change_value": round(forecast_balance - current_balance, 2),        "change_percentage": round(change_percentage, 2),        "elapsed_days": elapsed_days,        "remaining_days": remaining_days,        "confidence_level": confidence_level,        "input_summary": {            "first_day": first_day.isoformat(),            "last_day": last_day.isoformat(),            "calculation_until": today.isoformat(),            "elapsed_days": elapsed_days,            "remaining_days": remaining_days        }    }    cur.execute("""        INSERT INTO ai_predictions (            id,            user_id,            prediction_type,            prediction_date,            target_date,            current_value,            predicted_value,            change_value,            change_percentage,            input_summary,            prediction_payload,            confidence_level,            notes,            created_at,            updated_at        )        VALUES (            gen_random_uuid(),            %s,            %s,            %s,            %s,            %s,            %s,            %s,            %s,            %s::jsonb,            %s::jsonb,            %s,            %s,            NOW(),            NOW()        )    """, (        user_id,        "financial_forecast",        result["prediction_date"],        result["target_date"],        result["current_balance"],        result["forecast_balance"],        result["change_value"],        result["change_percentage"],        psycopg2.extras.Json(result["input_summary"]),        psycopg2.extras.Json(result),        confidence_level,        "Financial forecast generated using average daily cash flow."    ))    conn.commit()    cur.close()    conn.close()    return result

7. Main Python Runner
Create:
nano run_predictions.py
Add:
import argparseimport jsonfrom predictions.weight_prediction import calculate_weight_predictionfrom predictions.financial_forecast import calculate_financial_forecastdef main():    parser = argparse.ArgumentParser(description="NIX LIFE OS Prediction Models")    parser.add_argument("--user-id", required=True, help="User UUID")    parser.add_argument("--type", required=True, choices=[        "weight",        "finance",        "all"    ])    parser.add_argument("--days-ahead", type=int, default=30)    parser.add_argument("--month", required=False, help="Target month YYYY-MM")    args = parser.parse_args()    results = {}    if args.type in ["weight", "all"]:        results["weight_prediction"] = calculate_weight_prediction(            user_id=args.user_id,            days_ahead=args.days_ahead        )    if args.type in ["finance", "all"]:        results["financial_forecast"] = calculate_financial_forecast(            user_id=args.user_id,            target_month=args.month        )    print(json.dumps(results, indent=4))if __name__ == "__main__":    main()

8. Test Python Predictions
Activate venv:
cd /u01/nix-life-os/ai-enginesource venv/bin/activate
Run weight prediction:
python run_predictions.py \  --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 \  --type=weight \  --days-ahead=30
Run finance forecast:
python run_predictions.py \  --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 \  --type=finance \  --month=2026-04
Run all:
python run_predictions.py \  --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 \  --type=all \  --days-ahead=30 \  --month=2026-04

9. Laravel Command to Run Predictions
Create command:
cd /u01/nix-life-os/backendphp artisan make:command RunPredictionModels
Open:
nano app/Console/Commands/RunPredictionModels.php
Replace with:
<?phpnamespace App\Console\Commands;use Illuminate\Console\Command;use Symfony\Component\Process\Process;class RunPredictionModels extends Command{    protected $signature = 'ai:predictions                            {--user-id= : User UUID}                            {--type=all : Prediction type: weight, finance, all}                            {--days-ahead=30 : Days ahead for weight prediction}                            {--month= : Forecast month YYYY-MM}';    protected $description = 'Run AI prediction models for weight and financial forecast';    public function handle(): int    {        $userId = $this->option('user-id');        $type = $this->option('type');        $daysAhead = $this->option('days-ahead');        $month = $this->option('month');        if (!$userId) {            $this->error('Missing --user-id option.');            return self::FAILURE;        }        $aiEnginePath = base_path('../ai-engine');        $command = [            $aiEnginePath . '/venv/bin/python',            $aiEnginePath . '/run_predictions.py',            '--user-id=' . $userId,            '--type=' . $type,            '--days-ahead=' . $daysAhead,        ];        if ($month) {            $command[] = '--month=' . $month;        }        $process = new Process($command, $aiEnginePath);        $process->setTimeout(300);        $this->info('Running prediction models...');        $process->run();        if (!$process->isSuccessful()) {            $this->error($process->getErrorOutput());            return self::FAILURE;        }        $this->info($process->getOutput());        return self::SUCCESS;    }}
Test:
php artisan ai:predictions \  --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 \  --type=all \  --days-ahead=30 \  --month=2026-04

10. Laravel API Controller
Create controller:
php artisan make:controller Api/V1/AiPredictionController
Open:
nano app/Http/Controllers/Api/V1/AiPredictionController.php
Add:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Models\AiPrediction;use Illuminate\Http\Request;use Symfony\Component\Process\Process;class AiPredictionController extends Controller{    public function index(Request $request)    {        $user = $request->user();        $query = AiPrediction::query()            ->where('user_id', $user->id)            ->orderByDesc('created_at');        if ($request->filled('type')) {            $query->where('prediction_type', $request->type);        }        return response()->json([            'status' => true,            'data' => $query->limit(50)->get(),        ]);    }    public function latest(Request $request)    {        $user = $request->user();        $weight = AiPrediction::where('user_id', $user->id)            ->where('prediction_type', 'weight_prediction')            ->latest()            ->first();        $finance = AiPrediction::where('user_id', $user->id)            ->where('prediction_type', 'financial_forecast')            ->latest()            ->first();        return response()->json([            'status' => true,            'data' => [                'weight_prediction' => $weight,                'financial_forecast' => $finance,            ],        ]);    }    public function run(Request $request)    {        $request->validate([            'type' => ['nullable', 'in:weight,finance,all'],            'days_ahead' => ['nullable', 'integer', 'min:1', 'max:365'],            'month' => ['nullable', 'date_format:Y-m'],        ]);        $user = $request->user();        $type = $request->input('type', 'all');        $daysAhead = $request->input('days_ahead', 30);        $month = $request->input('month');        $aiEnginePath = base_path('../ai-engine');        $command = [            $aiEnginePath . '/venv/bin/python',            $aiEnginePath . '/run_predictions.py',            '--user-id=' . $user->id,            '--type=' . $type,            '--days-ahead=' . $daysAhead,        ];        if ($month) {            $command[] = '--month=' . $month;        }        $process = new Process($command, $aiEnginePath);        $process->setTimeout(300);        $process->run();        if (!$process->isSuccessful()) {            return response()->json([                'status' => false,                'message' => 'Prediction model failed.',                'error' => $process->getErrorOutput(),            ], 500);        }        return response()->json([            'status' => true,            'message' => 'Prediction models executed successfully.',            'output' => json_decode($process->getOutput(), true),        ]);    }}

11. Add API Routes
Open:
nano routes/api.php
Inside your protected Sanctum group, add:
use App\Http\Controllers\Api\V1\AiPredictionController;
Then inside:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
Add:
Route::prefix('ai/predictions')->group(function () {    Route::get('/', [AiPredictionController::class, 'index']);    Route::get('/latest', [AiPredictionController::class, 'latest']);    Route::post('/run', [AiPredictionController::class, 'run']);});
Final route structure should include:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    Route::prefix('ai/predictions')->group(function () {        Route::get('/', [AiPredictionController::class, 'index']);        Route::get('/latest', [AiPredictionController::class, 'latest']);        Route::post('/run', [AiPredictionController::class, 'run']);    });});
Clear cache:
php artisan optimize:clearphp artisan route:list | grep predictions

12. API Test Commands
Use your token:
TOKEN="YOUR_TOKEN_HERE"
Run all predictions:
curl -X POST http://127.0.0.1:8000/api/v1/ai/predictions/run \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "type": "all",    "days_ahead": 30,    "month": "2026-04"  }'
Run only weight prediction:
curl -X POST http://127.0.0.1:8000/api/v1/ai/predictions/run \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "type": "weight",    "days_ahead": 30  }'
Run only financial forecast:
curl -X POST http://127.0.0.1:8000/api/v1/ai/predictions/run \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "type": "finance",    "month": "2026-04"  }'
Get latest predictions:
curl http://127.0.0.1:8000/api/v1/ai/predictions/latest \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Get all predictions:
curl http://127.0.0.1:8000/api/v1/ai/predictions \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Filter by type:
curl "http://127.0.0.1:8000/api/v1/ai/predictions?type=weight_prediction" \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
curl "http://127.0.0.1:8000/api/v1/ai/predictions?type=financial_forecast" \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

13. Add Scheduler
Open:
nano app/Console/Kernel.php
Inside schedule() add:
$schedule->command('ai:predictions --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 --type=all --days-ahead=30')    ->dailyAt('23:45');
Check schedule:
php artisan schedule:list
Expected:
45 23 * * * php artisan ai:predictions ...

14. Important PostgreSQL Checks
Check if table exists:
php artisan tinker
Then:
Schema::hasTable('ai_predictions');
Should return:
true
Check records:
psql -U postgres -d nixlifeos_db
Then:
SELECT     prediction_type,    prediction_date,    target_date,    current_value,    predicted_value,    change_value,    confidence_level,    created_atFROM ai_predictionsORDER BY created_at DESC;

15. Expected API Output
Example output:
{  "status": true,  "message": "Prediction models executed successfully.",  "output": {    "weight_prediction": {      "status": "success",      "user_id": "019d7c17-adcf-713f-b853-328a2fb65e57",      "prediction_type": "weight_prediction",      "current_weight": 64.0,      "predicted_weight": 62.5,      "change_value": -1.5,      "change_percentage": -2.34,      "average_daily_change": -0.05,      "days_ahead": 30,      "confidence_level": "medium"    },    "financial_forecast": {      "status": "success",      "current_balance": 1000.0,      "forecast_balance": 1200.0,      "forecast_income": 1500.0,      "forecast_expenses": 900.0,      "forecast_net_cash_flow": 600.0,      "confidence_level": "medium"    }  }}

16. Step 19 Final Checklist
After completing this step, you should have:
✅ ai_predictions table✅ AiPrediction Laravel model✅ Python weight prediction model✅ Python financial forecast model✅ run_predictions.py runner✅ Laravel ai:predictions command✅ API endpoint to run predictions✅ API endpoint to view latest predictions✅ Scheduler-ready prediction system

17. Best Next Step
After Step 19, continue with:
🔹 STEP 20 — Prediction Dashboard UIBuild Vue UI for:- Weight forecast card- Weight trend chart- Financial forecast card- Income vs expenses projection- Prediction confidence badges- Run prediction button