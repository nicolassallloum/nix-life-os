<?php

namespace App\Http\Requests\Todo;

use App\Models\TodoTask;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTodoTaskRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = auth()->id();

        return [
            'project_id' => [
                'nullable',
                'integer',
                Rule::exists('todo_projects', 'id')->where('user_id', $userId),
            ],

            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],

            'task_type' => ['sometimes', 'nullable', Rule::in(TodoTask::TYPES)],
            'status' => ['sometimes', 'nullable', Rule::in(TodoTask::STATUSES)],
            'priority' => ['sometimes', 'nullable', Rule::in(TodoTask::PRIORITIES)],

            'points' => ['nullable', 'integer', 'min:0'],

            'due_date' => ['nullable', 'date'],
            'completed_at' => ['nullable', 'date'],

            'sort_order' => ['nullable', 'integer', 'min:0'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
