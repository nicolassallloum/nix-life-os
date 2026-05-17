<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AutomationRule;
use App\Models\AutomationTriggerLog;
use App\Services\AutomationEngineService;
use Illuminate\Http\Request;

class AutomationRuleController extends Controller
{
    public function index(Request $request)
    {
        $rules = AutomationRule::query()
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'status' => true,
            'data' => $rules,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'rule_name' => ['required', 'string', 'max:255'],
            'module' => ['required', 'string', 'max:100'],
            'trigger_type' => ['required', 'string', 'max:100'],
            'conditions' => ['nullable', 'array'],
            'action_type' => ['nullable', 'string', 'max:100'],
            'action_payload' => ['nullable', 'array'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $rule = AutomationRule::create([
            'user_id' => $request->user()->id,
            'rule_name' => $validated['rule_name'],
            'module' => $validated['module'],
            'trigger_type' => $validated['trigger_type'],
            'conditions' => $validated['conditions'] ?? [],
            'action_type' => $validated['action_type'] ?? 'create_notification',
            'action_payload' => $validated['action_payload'] ?? [],
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Automation rule created successfully.',
            'data' => $rule,
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $rule = AutomationRule::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'status' => true,
            'data' => $rule,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $rule = AutomationRule::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $validated = $request->validate([
            'rule_name' => ['sometimes', 'string', 'max:255'],
            'module' => ['sometimes', 'string', 'max:100'],
            'trigger_type' => ['sometimes', 'string', 'max:100'],
            'conditions' => ['sometimes', 'nullable', 'array'],
            'action_type' => ['sometimes', 'string', 'max:100'],
            'action_payload' => ['sometimes', 'nullable', 'array'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $rule->update($validated);

        return response()->json([
            'status' => true,
            'message' => 'Automation rule updated successfully.',
            'data' => $rule,
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $rule = AutomationRule::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $rule->delete();

        return response()->json([
            'status' => true,
            'message' => 'Automation rule deleted successfully.',
        ]);
    }

    public function run(Request $request, AutomationEngineService $service)
    {
        $results = $service->runForUser($request->user()->id);

        return response()->json([
            'status' => true,
            'message' => 'Automation engine executed.',
            'data' => $results,
        ]);
    }

    public function logs(Request $request)
    {
        $logs = AutomationTriggerLog::query()
            ->where('user_id', $request->user()->id)
            ->with('rule')
            ->latest()
            ->limit(100)
            ->get();

        return response()->json([
            'status' => true,
            'data' => $logs,
        ]);
    }

    public function toggle(Request $request, string $id)
    {
        $rule = AutomationRule::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $rule->update([
            'is_active' => !$rule->is_active,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Automation rule status updated.',
            'data' => $rule,
        ]);
    }
}
