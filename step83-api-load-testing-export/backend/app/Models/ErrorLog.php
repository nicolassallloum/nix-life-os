<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ErrorLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'level',
        'module',
        'exception_class',
        'message',
        'file',
        'line',
        'request_method',
        'request_url',
        'request_payload',
        'trace',
        'metadata',
        'ip_address',
        'user_agent',
        'created_at',
    ];

    protected $casts = [
        'request_payload' => 'array',
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];
}