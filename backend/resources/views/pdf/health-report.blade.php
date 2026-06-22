<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        @page { margin: 24px 26px 32px 26px; }

        body {
            font-family: DejaVu Sans, sans-serif;
            color: #0f172a;
            font-size: 11px;
            line-height: 1.45;
            background: #ffffff;
        }

        .header {
            background: #f8fafc;
            border: 1px solid #dbeafe;
            border-left: 7px solid #0f766e;
            padding: 16px 18px;
            margin-bottom: 14px;
        }

        .brand-row {
            width: 100%;
            border-collapse: collapse;
        }

        .brand-name {
            font-size: 12px;
            font-weight: bold;
            color: #0f766e;
            text-transform: uppercase;
            letter-spacing: .08em;
        }

        .report-title {
            font-size: 28px;
            font-weight: bold;
            color: #0f172a;
            margin-top: 3px;
        }

        .period {
            color: #475569;
            font-size: 12px;
            margin-top: 4px;
        }

        .status-badge,
        .badge {
            display: inline-block;
            border-radius: 999px;
            padding: 4px 9px;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: .04em;
            white-space: nowrap;
        }

        .badge-good { background: #dcfce7; color: #166534; border: 1px solid #86efac; }
        .badge-warning { background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }
        .badge-danger { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
        .badge-neutral { background: #e2e8f0; color: #334155; border: 1px solid #cbd5e1; }
        .badge-info { background: #dbeafe; color: #1d4ed8; border: 1px solid #93c5fd; }

        .meta {
            color: #64748b;
            font-size: 10px;
            margin-top: 8px;
        }

        .section {
            margin-top: 13px;
            page-break-inside: avoid;
        }

        .section-title {
            background: #eefdfb;
            color: #0f172a;
            border-left: 5px solid #0f766e;
            padding: 8px 10px;
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 8px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        table.data th {
            background: #f8fafc;
            color: #334155;
            font-weight: bold;
            text-align: left;
            border: 1px solid #e2e8f0;
            padding: 6px 7px;
            font-size: 10px;
        }

        table.data td {
            border: 1px solid #e2e8f0;
            padding: 6px 7px;
            font-size: 10px;
            vertical-align: top;
        }

        .kpi-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 6px;
            margin-left: -6px;
            margin-right: -6px;
        }

        .kpi-card {
            width: 25%;
            border: 1px solid #dbeafe;
            background: #f8fafc;
            padding: 10px;
            vertical-align: top;
            border-radius: 10px;
        }

        .kpi-label {
            color: #64748b;
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: .06em;
            font-weight: bold;
        }

        .kpi-value {
            font-size: 18px;
            font-weight: bold;
            color: #0f172a;
            margin-top: 4px;
            margin-bottom: 5px;
        }

        .kpi-note {
            color: #64748b;
            font-size: 9px;
            margin-top: 5px;
        }

        .summary-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            padding: 10px;
        }

        .summary-list {
            margin: 6px 0 0 14px;
            padding: 0;
        }

        .summary-list li {
            margin-bottom: 4px;
        }

        .warning {
            background: #fff7ed;
            border: 1px solid #fed7aa;
            color: #9a3412;
            padding: 10px;
            margin-top: 8px;
            font-weight: bold;
        }

        .clinical-note {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            color: #1e3a8a;
            padding: 10px;
            margin-top: 8px;
        }

        .note-box {
            min-height: 68px;
            background: #ffffff;
            border: 1px dashed #94a3b8;
            padding: 12px;
            color: #475569;
        }

        .progress-wrap {
            background: #e2e8f0;
            border-radius: 999px;
            height: 8px;
            overflow: hidden;
            margin-top: 6px;
        }

        .progress-fill {
            background: #0f766e;
            height: 8px;
        }

        .muted {
            color: #64748b;
        }

        .small {
            font-size: 9px;
            color: #64748b;
        }

        .footer {
            margin-top: 18px;
            padding-top: 10px;
            border-top: 1px solid #e2e8f0;
            font-size: 9px;
            color: #64748b;
            text-align: center;
        }
    </style>
</head>
<body>
@php
    $summary = $report['summary'] ?? [];
    $nutrition = $report['nutrition']['totals'] ?? [];
    $hydration = $report['hydration'] ?? [];
    $weight = $report['weight'] ?? [];
    $steps = $report['steps'] ?? [];
    $labs = $report['lab_results'] ?? [];
    $meds = $report['medication_adherence'] ?? [];
    $warnings = $report['nutrition']['ckd_warnings'] ?? [];

    $period = $report['period'] ?? [];
    $periodStart = $period['start_date'] ?? $period['from_date'] ?? $period['date'] ?? null;
    $periodEnd = $period['end_date'] ?? $period['to_date'] ?? $period['date'] ?? $periodStart;

    $periodDays = 1;
    if ($periodStart && $periodEnd && strtotime($periodStart) && strtotime($periodEnd)) {
        $periodDays = max(1, (int) floor((strtotime($periodEnd) - strtotime($periodStart)) / 86400) + 1);
    }

    $dailyCaloriesGoal = (float) ($goals->daily_calories_goal ?? 0);
    $dailyWaterGoal = (float) ($goals->daily_water_goal_ml ?? 0);
    $dailyStepsGoal = (float) ($goals->daily_steps_goal ?? 0);
    $targetWeight = $goals->target_weight_kg ?? null;

    $calorieTarget = $dailyCaloriesGoal > 0 ? $dailyCaloriesGoal * $periodDays : 0;
    $waterTarget = $dailyWaterGoal > 0 ? $dailyWaterGoal * $periodDays : 0;
    $stepsTarget = $dailyStepsGoal > 0 ? $dailyStepsGoal * $periodDays : 0;

    $calories = (float) ($nutrition['calories'] ?? $summary['total_calories'] ?? 0);
    $waterMl = (float) ($hydration['total_water_ml'] ?? $summary['total_water_ml'] ?? 0);
    $totalSteps = (float) ($steps['total_steps'] ?? 0);
    $adherence = (float) ($meds['adherence_percent'] ?? 0);

    $stepsPercent = $stepsTarget > 0 ? min(100, round(($totalSteps / $stepsTarget) * 100)) : 0;
    $waterPercent = $waterTarget > 0 ? min(100, round(($waterMl / $waterTarget) * 100)) : 0;
    $caloriePercent = $calorieTarget > 0 ? min(100, round(($calories / $calorieTarget) * 100)) : 0;
    $medPercent = min(100, round($adherence));

    $labCollection = collect($lab_tests ?? []);
    $medCollection = collect($medications ?? [])->unique(function ($medication) {
        return strtolower(trim(
            ($medication->medication_name ?? '') . '|' .
            ($medication->dosage ?? $medication->daily_dose ?? '') . '|' .
            ($medication->frequency ?? '')
        ));
    })->values();

    $totalLabs = (int) ($labs['total_tests'] ?? $labCollection->count());
    $abnormalLabs = (int) ($labs['abnormal_tests'] ?? 0);
    $pendingLabs = $labCollection->filter(fn ($lab) => in_array(strtolower((string) ($lab->status ?? '')), ['pending', 'pending_review', 'review'], true))->count();
    $approvedLabs = $labCollection->filter(fn ($lab) => strtolower((string) ($lab->status ?? '')) === 'approved')->count();
    $latestLabDate = $labCollection->pluck('test_date')->filter()->sort()->last() ?: 'N/A';

    $baseStatus = (string) ($summary['health_status'] ?? 'Needs Attention');
    $displayStatus = $baseStatus === 'Moderate' ? 'Needs Attention' : $baseStatus;

    if (($nutrition['sodium_mg'] ?? 0) > 3500 || $adherence < 40 || $abnormalLabs > 0) {
        $displayStatus = 'Critical';
    }

    $badgeClass = function ($status) {
        $value = strtolower((string) $status);

        if (in_array($value, ['good', 'within goal', 'active', 'approved', 'normal', 'taken', 'completed'], true)) {
            return 'badge-good';
        }

        if (in_array($value, ['critical', 'abnormal', 'high', 'low', 'missed', 'stopped'], true)) {
            return 'badge-danger';
        }

        if (in_array($value, ['needs attention', 'moderate', 'above target', 'pending', 'pending_review', 'paused', 'skipped'], true)) {
            return 'badge-warning';
        }

        return 'badge-neutral';
    };

    $targetStatus = function ($actual, $target, $higherIsBad = true) {
        if (! $target || (float) $target <= 0) {
            return ['No Target Set', 'badge-neutral'];
        }

        if ($higherIsBad && (float) $actual > (float) $target) {
            return ['Above Target', 'badge-danger'];
        }

        if (! $higherIsBad && (float) $actual < (float) $target) {
            return ['Below Target', 'badge-warning'];
        }

        return ['Within Goal', 'badge-good'];
    };

    $weightChange = $weight['change_kg'] ?? null;
    $weightInterpretation = 'Stable';
    if ($weightChange !== null && is_numeric($weightChange)) {
        $weightInterpretation = ((float) $weightChange > 0) ? 'Increased' : (((float) $weightChange < 0) ? 'Decreased' : 'Stable');
    }

    $summaryItems = [];
    $summaryItems[] = $displayStatus === 'Good'
        ? 'Overall report status is good for the selected period.'
        : 'Overall report status requires attention for the selected period.';

    $summaryItems[] = $stepsTarget > 0 && $totalSteps >= $stepsTarget
        ? 'Steps target achieved for the selected period.'
        : 'Steps progress should be reviewed against the configured target.';

    $summaryItems[] = $waterTarget > 0 && $waterMl >= ($waterTarget * 0.8)
        ? 'Hydration is close to or within the configured target.'
        : 'Hydration intake may be below the configured target.';

    if (collect($warnings)->contains(true)) {
        $summaryItems[] = 'Nutrition intake exceeded one or more CKD-sensitive tracking thresholds.';
    }

    if ($adherence < 80) {
        $summaryItems[] = 'Medication adherence requires attention.';
    }
@endphp

<div class="header">
    <table class="brand-row">
        <tr>
            <td>
                <div class="brand-name">Nix Life OS</div>
                <div class="report-title">Health Report</div>
                <div class="period">{{ $period_label }}</div>
                <div class="meta">
                    Generated: {{ $generated_at }} |
                    Export Date: {{ $export_date }} |
                    Report Period: {{ $periodStart ?? 'N/A' }} to {{ $periodEnd ?? 'N/A' }}
                </div>
            </td>
            <td style="text-align:right; width:160px;">
                <span class="status-badge {{ $badgeClass($displayStatus) }}">{{ $displayStatus }}</span>
            </td>
        </tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Patient / Profile Information</div>
    <table class="data">
        <tr>
            <th>Name</th>
            <td>{{ $user['name'] ?? 'N/A' }}</td>
            <th>Email</th>
            <td>{{ $user['email'] ?? 'N/A' }}</td>
        </tr>
        <tr>
            <th>User ID</th>
            <td>{{ $user['id'] ?? 'N/A' }}</td>
            <th>Report Period</th>
            <td>{{ $periodStart ?? 'N/A' }} to {{ $periodEnd ?? 'N/A' }}</td>
        </tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Executive Summary</div>
    <div class="summary-box">
        <strong>Overall Status:</strong>
        <span class="badge {{ $badgeClass($displayStatus) }}">{{ $displayStatus }}</span>
        <ul class="summary-list">
            @foreach($summaryItems as $item)
                <li>{{ $item }}</li>
            @endforeach
        </ul>
        <div class="clinical-note">
            This report is for tracking only. Nutrition targets should be confirmed with a nephrologist or renal dietitian.
        </div>
    </div>
</div>

<div class="section">
    <div class="section-title">Health Overview</div>
    <table class="kpi-table">
        <tr>
            <td class="kpi-card">
                <div class="kpi-label">Health Status</div>
                <div class="kpi-value">{{ $displayStatus }}</div>
                <span class="badge {{ $badgeClass($displayStatus) }}">{{ $displayStatus }}</span>
                <div class="kpi-note">Overall tracking status.</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Calories</div>
                <div class="kpi-value">{{ number_format($calories) }}</div>
                @php [$calLabel, $calClass] = $targetStatus($calories, $calorieTarget, true); @endphp
                <span class="badge {{ $calClass }}">{{ $calLabel }}</span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $caloriePercent }}%;"></div></div>
                <div class="kpi-note">Target: {{ $calorieTarget ? number_format($calorieTarget) . ' kcal' : 'N/A' }}</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Water</div>
                <div class="kpi-value">{{ $hydration['total_water_liters'] ?? 0 }} L</div>
                @php [$waterLabel, $waterClass] = $targetStatus($waterMl, $waterTarget, false); @endphp
                <span class="badge {{ $waterClass }}">{{ $waterLabel }}</span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $waterPercent }}%;"></div></div>
                <div class="kpi-note">Target: {{ $waterTarget ? number_format($waterTarget) . ' ml' : 'N/A' }}</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Medication</div>
                <div class="kpi-value">{{ $adherence }}%</div>
                <span class="badge {{ $adherence >= 80 ? 'badge-good' : 'badge-warning' }}">
                    {{ $adherence >= 80 ? 'Good' : 'Needs Attention' }}
                </span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $medPercent }}%;"></div></div>
                <div class="kpi-note">Taken: {{ $meds['taken_doses'] ?? 0 }} / {{ $meds['total_doses'] ?? 0 }}</div>
            </td>
        </tr>
        <tr>
            <td class="kpi-card">
                <div class="kpi-label">Steps</div>
                <div class="kpi-value">{{ number_format($totalSteps) }}</div>
                <span class="badge {{ $stepsTarget > 0 && $totalSteps >= $stepsTarget ? 'badge-good' : 'badge-warning' }}">
                    {{ $stepsTarget > 0 && $totalSteps >= $stepsTarget ? 'Goal Achieved' : 'Below Goal' }}
                </span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $stepsPercent }}%;"></div></div>
                <div class="kpi-note">Target: {{ $stepsTarget ? number_format($stepsTarget) : 'N/A' }}</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Weight</div>
                <div class="kpi-value">{{ $weight['latest_weight'] ?? 'N/A' }} kg</div>
                <span class="badge badge-info">{{ $weightInterpretation }}</span>
                <div class="kpi-note">Target: {{ $targetWeight ? $targetWeight . ' kg' : 'N/A' }}</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Lab Tests</div>
                <div class="kpi-value">{{ $totalLabs }}</div>
                <span class="badge {{ $abnormalLabs > 0 ? 'badge-danger' : 'badge-good' }}">
                    {{ $abnormalLabs > 0 ? 'Abnormal Found' : 'No Abnormal Flags' }}
                </span>
                <div class="kpi-note">Latest: {{ $latestLabDate }}</div>
            </td>
            <td class="kpi-card">
                <div class="kpi-label">Report Days</div>
                <div class="kpi-value">{{ $periodDays }}</div>
                <span class="badge badge-neutral">Selected Period</span>
                <div class="kpi-note">{{ $periodStart ?? 'N/A' }} to {{ $periodEnd ?? 'N/A' }}</div>
            </td>
        </tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Health Goals</div>
    @if($goals)
        <table class="data">
            <tr>
                <th>Daily Steps</th>
                <td>{{ number_format((float) ($goals->daily_steps_goal ?? 0)) }}</td>
                <th>Target Weight</th>
                <td>{{ $goals->target_weight_kg ?? 'N/A' }} kg</td>
            </tr>
            <tr>
                <th>Daily Calories</th>
                <td>{{ number_format((float) ($goals->daily_calories_goal ?? 0)) }} kcal</td>
                <th>Daily Water</th>
                <td>{{ number_format((float) ($goals->daily_water_goal_ml ?? 0)) }} ml</td>
            </tr>
            <tr>
                <th>Protein Limit</th>
                <td>{{ $goals->protein_limit_g ?? 'N/A' }} g</td>
                <th>Sodium Limit</th>
                <td>{{ $goals->sodium_limit_mg ?? 'N/A' }} mg</td>
            </tr>
            <tr>
                <th>Potassium Limit</th>
                <td>{{ $goals->potassium_limit_mg ?? 'N/A' }} mg</td>
                <th>Phosphorus Limit</th>
                <td>{{ $goals->phosphorus_limit_mg ?? 'N/A' }} mg</td>
            </tr>
        </table>
    @else
        <div class="summary-box">No health goals were found for this user.</div>
    @endif
</div>

<div class="section">
    <div class="section-title">Nutrition Summary</div>
    <table class="data">
        <tr>
            <th>Nutrient</th>
            <th>Actual</th>
            <th>Target / Limit</th>
            <th>Status</th>
        </tr>
        @php
            $nutritionRows = [
                ['Calories', $calories, 'kcal', $calorieTarget, true],
                ['Protein', (float) ($nutrition['protein_g'] ?? 0), 'g', ($goals->protein_limit_g ?? 0) ? (float) $goals->protein_limit_g * $periodDays : 0, true],
                ['Sodium', (float) ($nutrition['sodium_mg'] ?? 0), 'mg', ($goals->sodium_limit_mg ?? 0) ? (float) $goals->sodium_limit_mg * $periodDays : 0, true],
                ['Potassium', (float) ($nutrition['potassium_mg'] ?? 0), 'mg', ($goals->potassium_limit_mg ?? 0) ? (float) $goals->potassium_limit_mg * $periodDays : 0, true],
                ['Phosphorus', (float) ($nutrition['phosphorus_mg'] ?? 0), 'mg', ($goals->phosphorus_limit_mg ?? 0) ? (float) $goals->phosphorus_limit_mg * $periodDays : 0, true],
                ['Carbs', (float) ($nutrition['carbs_g'] ?? 0), 'g', 0, true],
                ['Fat', (float) ($nutrition['fat_g'] ?? 0), 'g', 0, true],
            ];
        @endphp
        @foreach($nutritionRows as $row)
            @php [$label, $class] = $targetStatus($row[1], $row[3], $row[4]); @endphp
            <tr>
                <td>{{ $row[0] }}</td>
                <td>{{ number_format($row[1]) }} {{ $row[2] }}</td>
                <td>{{ $row[3] ? number_format($row[3]) . ' ' . $row[2] : 'N/A' }}</td>
                <td><span class="badge {{ $class }}">{{ $label }}</span></td>
            </tr>
        @endforeach
    </table>

    @if(collect($warnings)->contains(true))
        <div class="warning">
            CKD nutrition warning: one or more nutrition values exceeded CKD-sensitive tracking thresholds during this selected period.
        </div>
    @endif
</div>

<div class="section">
    <div class="section-title">Steps Summary</div>
    <table class="data">
        <tr>
            <th>Total Steps</th>
            <td>{{ number_format($totalSteps) }}</td>
            <th>Average Steps</th>
            <td>{{ number_format((float) ($steps['average_steps'] ?? 0)) }}</td>
        </tr>
        <tr>
            <th>Total Kilometers</th>
            <td>{{ $steps['total_kilometers'] ?? 0 }} km</td>
            <th>Calories Burned</th>
            <td>{{ $steps['total_calories_burned'] ?? 0 }}</td>
        </tr>
        <tr>
            <th>Goal Status</th>
            <td colspan="3">
                <span class="badge {{ $stepsTarget > 0 && $totalSteps >= $stepsTarget ? 'badge-good' : 'badge-warning' }}">
                    {{ $stepsTarget > 0 && $totalSteps >= $stepsTarget ? 'Goal Achieved' : 'Below Goal' }}
                </span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $stepsPercent }}%;"></div></div>
                <span class="small">{{ $stepsPercent }}% of selected-period target</span>
            </td>
        </tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Hydration Summary</div>
    <table class="data">
        <tr>
            <th>Total Water</th>
            <td>{{ number_format($waterMl) }} ml</td>
            <th>Total Liters</th>
            <td>{{ $hydration['total_water_liters'] ?? 0 }} L</td>
        </tr>
        <tr>
            <th>Target</th>
            <td>{{ $waterTarget ? number_format($waterTarget) . ' ml' : 'N/A' }}</td>
            <th>Status</th>
            <td>
                <span class="badge {{ $waterClass }}">{{ $waterLabel }}</span>
                <div class="progress-wrap"><div class="progress-fill" style="width: {{ $waterPercent }}%;"></div></div>
                <span class="small">{{ $waterPercent }}% of selected-period target</span>
            </td>
        </tr>
    </table>
</div>

<div class="section">
    <div class="section-title">Weight History</div>
    <table class="data">
        <tr>
            <th>Start Weight</th>
            <td>{{ $weight['start_weight'] ?? 'N/A' }} kg</td>
            <th>Latest Weight</th>
            <td>{{ $weight['latest_weight'] ?? 'N/A' }} kg</td>
            <th>Change</th>
            <td>{{ $weight['change_kg'] ?? 'N/A' }} kg</td>
        </tr>
        <tr>
            <th>Target Weight</th>
            <td>{{ $targetWeight ? $targetWeight . ' kg' : 'N/A' }}</td>
            <th>Interpretation</th>
            <td colspan="3"><span class="badge badge-info">{{ $weightInterpretation }}</span></td>
        </tr>
    </table>

    @if(!empty($weight['items']) && count($weight['items']))
        <table class="data">
            <tr>
                <th>Date</th>
                <th>Weight</th>
            </tr>
            @foreach($weight['items'] as $item)
                <tr>
                    <td>{{ $item->log_date }}</td>
                    <td>{{ $item->weight_kg }} kg</td>
                </tr>
            @endforeach
        </table>
    @endif
</div>

<div class="section">
    <div class="section-title">Medications</div>
    <table class="data">
        <tr>
            <th>Total Scheduled Doses</th>
            <td>{{ $meds['total_doses'] ?? 0 }}</td>
            <th>Taken</th>
            <td>{{ $meds['taken_doses'] ?? 0 }}</td>
            <th>Missed</th>
            <td>{{ $meds['missed_doses'] ?? 0 }}</td>
        </tr>
        <tr>
            <th>Skipped</th>
            <td>{{ $meds['skipped_doses'] ?? 0 }}</td>
            <th>Pending</th>
            <td>{{ $meds['pending_doses'] ?? 0 }}</td>
            <th>Adherence</th>
            <td><span class="badge {{ $adherence >= 80 ? 'badge-good' : 'badge-warning' }}">{{ $adherence }}%</span></td>
        </tr>
    </table>

    @if($medCollection->count())
        <table class="data">
            <tr>
                <th>Medication</th>
                <th>Dosage</th>
                <th>Frequency</th>
                <th>Status</th>
                <th>Doctor</th>
            </tr>
            @foreach($medCollection as $medication)
                @php
                    $medStatus = ucfirst(strtolower((string) ($medication->status ?? 'N/A')));
                @endphp
                <tr>
                    <td>{{ $medication->medication_name }}</td>
                    <td>{{ $medication->dosage ?? $medication->daily_dose ?? 'N/A' }}</td>
                    <td>{{ $medication->frequency ?? 'N/A' }}</td>
                    <td><span class="badge {{ $badgeClass($medStatus) }}">{{ $medStatus }}</span></td>
                    <td>{{ $medication->doctor_name ?? $medication->prescribed_by ?? 'N/A' }}</td>
                </tr>
            @endforeach
        </table>
    @else
        <div class="summary-box">No medications found.</div>
    @endif
</div>

<div class="section">
    <div class="section-title">Lab Tests</div>
    <table class="data">
        <tr>
            <th>Total Tests</th>
            <td>{{ $totalLabs }}</td>
            <th>Abnormal Tests</th>
            <td>{{ $abnormalLabs }}</td>
            <th>Latest Test Date</th>
            <td>{{ $latestLabDate }}</td>
        </tr>
        <tr>
            <th>Pending Review</th>
            <td>{{ $pendingLabs }}</td>
            <th>Approved</th>
            <td>{{ $approvedLabs }}</td>
            <th>Status</th>
            <td><span class="badge {{ $abnormalLabs > 0 ? 'badge-danger' : 'badge-good' }}">{{ $abnormalLabs > 0 ? 'Review Required' : 'No Abnormal Flags' }}</span></td>
        </tr>
    </table>

    @if($labCollection->count())
        <table class="data">
            <tr>
                <th>Date</th>
                <th>Test</th>
                <th>Result</th>
                <th>Reference</th>
                <th>Status</th>
            </tr>
            @foreach($labCollection as $lab)
                @php $labStatus = $lab->status ?? (!empty($lab->is_abnormal) ? 'abnormal' : 'normal'); @endphp
                <tr>
                    <td>{{ $lab->test_date }}</td>
                    <td>{{ $lab->test_name }}</td>
                    <td>{{ trim(($lab->result_value ?? 'N/A') . ' ' . ($lab->unit ?? '')) }}</td>
                    <td>{{ $lab->reference_range ?? 'N/A' }}</td>
                    <td>
                        <span class="badge {{ $badgeClass($labStatus) }}">{{ str_replace('_', ' ', ucfirst($labStatus)) }}</span>
                        @if(!empty($lab->abnormal_reason))
                            <br><span class="small">{{ $lab->abnormal_reason }}</span>
                        @endif
                    </td>
                </tr>
            @endforeach
        </table>
    @else
        <div class="summary-box">No lab tests found.</div>
    @endif
</div>

<div class="section">
    <div class="section-title">Doctor Review Notes</div>
    <div class="note-box">
        This section is reserved for clinician notes, follow-up instructions, and treatment plan updates.
    </div>
</div>

<div class="footer">
    Generated by Nix Life OS. This report is for personal tracking and informational purposes only. It does not replace professional medical advice, diagnosis, or treatment.
</div>
</body>
</html>
