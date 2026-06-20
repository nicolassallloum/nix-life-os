<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        @page {
            margin: 26px;
        }

        body {
            font-family: DejaVu Sans, sans-serif;
            color: #0f172a;
            font-size: 12px;
            line-height: 1.45;
            background: #ffffff;
        }

        .header {
            border-bottom: 3px solid #0f766e;
            padding-bottom: 14px;
            margin-bottom: 18px;
        }

        .brand {
            font-size: 24px;
            font-weight: bold;
            color: #0f172a;
            margin: 0;
        }

        .subtitle {
            color: #0f766e;
            font-size: 13px;
            margin-top: 4px;
        }

        .meta {
            color: #475569;
            margin-top: 8px;
            font-size: 11px;
        }

        .section {
            margin-top: 16px;
            page-break-inside: avoid;
        }

        .section-title {
            background: #ecfeff;
            color: #0f172a;
            border-left: 5px solid #0f766e;
            padding: 8px 10px;
            font-size: 15px;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .grid {
            width: 100%;
            border-collapse: collapse;
        }

        .grid td {
            width: 25%;
            vertical-align: top;
            padding: 7px;
            border: 1px solid #e2e8f0;
        }

        .metric-label {
            color: #64748b;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .metric-value {
            font-size: 16px;
            font-weight: bold;
            margin-top: 3px;
            color: #0f172a;
        }

        table.data {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
        }

        table.data th {
            background: #f8fafc;
            color: #334155;
            font-weight: bold;
            text-align: left;
            border: 1px solid #e2e8f0;
            padding: 7px;
            font-size: 11px;
        }

        table.data td {
            border: 1px solid #e2e8f0;
            padding: 7px;
            font-size: 11px;
            vertical-align: top;
        }

        .note {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            padding: 10px;
            color: #475569;
            margin-top: 8px;
        }

        .warning {
            background: #fff7ed;
            border: 1px solid #fed7aa;
            color: #9a3412;
            padding: 10px;
            margin-top: 8px;
            font-weight: bold;
        }

        .footer {
            margin-top: 22px;
            padding-top: 10px;
            border-top: 1px solid #e2e8f0;
            font-size: 10px;
            color: #64748b;
            text-align: center;
        }

        .small {
            font-size: 10px;
            color: #64748b;
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
    @endphp

    <div class="header">
        <h1 class="brand">{{ $title }}</h1>
        <div class="subtitle">{{ $period_label }}</div>
        <div class="meta">
            Export Date: {{ $export_date }} |
            Generated At: {{ $generated_at }}
        </div>
    </div>

    <div class="section">
        <div class="section-title">Profile Information</div>
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
                <th>Report Status</th>
                <td>{{ $summary['health_status'] ?? 'N/A' }}</td>
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
            <div class="note">No health goals were found for this user.</div>
        @endif
    </div>

    <div class="section">
        <div class="section-title">Charts / Summary Snapshot</div>
        <table class="grid">
            <tr>
                <td>
                    <div class="metric-label">Health Status</div>
                    <div class="metric-value">{{ $summary['health_status'] ?? 'N/A' }}</div>
                </td>
                <td>
                    <div class="metric-label">Calories</div>
                    <div class="metric-value">{{ number_format((float) ($summary['total_calories'] ?? 0)) }}</div>
                </td>
                <td>
                    <div class="metric-label">Water</div>
                    <div class="metric-value">{{ $hydration['total_water_liters'] ?? 0 }} L</div>
                </td>
                <td>
                    <div class="metric-label">Medication</div>
                    <div class="metric-value">{{ $meds['adherence_percent'] ?? 0 }}%</div>
                </td>
            </tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">Calories & Nutrition Summary</div>
        <table class="data">
            <tr>
                <th>Calories</th>
                <th>Protein</th>
                <th>Carbs</th>
                <th>Fat</th>
                <th>Sodium</th>
                <th>Potassium</th>
                <th>Phosphorus</th>
            </tr>
            <tr>
                <td>{{ number_format((float) ($nutrition['calories'] ?? 0)) }} kcal</td>
                <td>{{ $nutrition['protein_g'] ?? 0 }} g</td>
                <td>{{ $nutrition['carbs_g'] ?? 0 }} g</td>
                <td>{{ $nutrition['fat_g'] ?? 0 }} g</td>
                <td>{{ $nutrition['sodium_mg'] ?? 0 }} mg</td>
                <td>{{ $nutrition['potassium_mg'] ?? 0 }} mg</td>
                <td>{{ $nutrition['phosphorus_mg'] ?? 0 }} mg</td>
            </tr>
        </table>

        @if(collect($warnings)->contains(true))
            <div class="warning">
                CKD nutrition warning: one or more configured nutrient limits are high for this selected period.
            </div>
        @endif
    </div>

    <div class="section">
        <div class="section-title">Steps Summary</div>
        <table class="data">
            <tr>
                <th>Total Steps</th>
                <td>{{ number_format((float) ($steps['total_steps'] ?? 0)) }}</td>
                <th>Average Steps</th>
                <td>{{ number_format((float) ($steps['average_steps'] ?? 0)) }}</td>
            </tr>
            <tr>
                <th>Total Kilometers</th>
                <td>{{ $steps['total_kilometers'] ?? 0 }} km</td>
                <th>Calories Burned</th>
                <td>{{ $steps['total_calories_burned'] ?? 0 }}</td>
            </tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">Hydration Summary</div>
        <table class="data">
            <tr>
                <th>Total Water</th>
                <td>{{ number_format((float) ($hydration['total_water_ml'] ?? 0)) }} ml</td>
                <th>Total Liters</th>
                <td>{{ $hydration['total_water_liters'] ?? 0 }} L</td>
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
                <th>Total Doses</th>
                <td>{{ $meds['total_doses'] ?? 0 }}</td>
                <th>Taken</th>
                <td>{{ $meds['taken_doses'] ?? 0 }}</td>
                <th>Missed</th>
                <td>{{ $meds['missed_doses'] ?? 0 }}</td>
            </tr>
        </table>

        @if($medications->count())
            <table class="data">
                <tr>
                    <th>Medication</th>
                    <th>Dosage</th>
                    <th>Frequency</th>
                    <th>Status</th>
                    <th>Doctor</th>
                </tr>
                @foreach($medications as $medication)
                    <tr>
                        <td>{{ $medication->medication_name }}</td>
                        <td>{{ $medication->dosage ?? $medication->daily_dose ?? 'N/A' }}</td>
                        <td>{{ $medication->frequency ?? 'N/A' }}</td>
                        <td>{{ $medication->status ?? 'N/A' }}</td>
                        <td>{{ $medication->doctor_name ?? $medication->prescribed_by ?? 'N/A' }}</td>
                    </tr>
                @endforeach
            </table>
        @else
            <div class="note">No medications found.</div>
        @endif
    </div>

    <div class="section">
        <div class="section-title">Lab Tests</div>
        <table class="data">
            <tr>
                <th>Total Tests</th>
                <td>{{ $labs['total_tests'] ?? 0 }}</td>
                <th>Abnormal Tests</th>
                <td>{{ $labs['abnormal_tests'] ?? 0 }}</td>
            </tr>
        </table>

        @if($lab_tests->count())
            <table class="data">
                <tr>
                    <th>Date</th>
                    <th>Test</th>
                    <th>Result</th>
                    <th>Reference</th>
                    <th>Status</th>
                </tr>
                @foreach($lab_tests as $lab)
                    <tr>
                        <td>{{ $lab->test_date }}</td>
                        <td>{{ $lab->test_name }}</td>
                        <td>{{ $lab->result_value }} {{ $lab->unit }}</td>
                        <td>{{ $lab->reference_range ?? 'N/A' }}</td>
                        <td>
                            {{ $lab->status ?? (!empty($lab->is_abnormal) ? 'abnormal' : 'normal') }}
                            @if(!empty($lab->abnormal_reason))
                                <br><span class="small">{{ $lab->abnormal_reason }}</span>
                            @endif
                        </td>
                    </tr>
                @endforeach
            </table>
        @else
            <div class="note">No lab tests found.</div>
        @endif
    </div>

    <div class="section">
        <div class="section-title">Doctor Notes Placeholder</div>
        <div class="note">
            This section is reserved for future doctor review notes, recommendations, and follow-up instructions.
        </div>
    </div>

    <div class="footer">
        Generated by Nix Life OS. This report is for personal tracking and should not replace professional medical advice.
    </div>
</body>
</html>
