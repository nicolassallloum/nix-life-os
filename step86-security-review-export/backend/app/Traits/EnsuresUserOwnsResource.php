<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

trait EnsuresUserOwnsResource
{
    protected function ensureUserOwnsResource(Request $request, Model $model): void
    {
        if ($request->user()->hasRole('admin')) {
            return;
        }

        if (! isset($model->user_id)) {
            abort(403, 'Resource ownership cannot be verified.');
        }

        if ((string) $model->user_id !== (string) $request->user()->id) {
            abort(403, 'Unauthorized action.');
        }
    }
}
