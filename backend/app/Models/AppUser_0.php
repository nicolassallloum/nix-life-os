<?php

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Foundation\Auth\User as Authenticatable;

class AppUser extends Authenticatable
{
    use HasApiTokens, HasUuids, Notifiable;

    protected $table = 'nix_life_os.app_user';
    protected $primaryKey = 'user_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'full_name',
        'email',
        'password_hash',
        'is_active',
    ];

    protected $hidden = [
        'password_hash',
    ];

    public function getAuthIdentifierName(): string
    {
        return 'user_id';
    }

    public function getAuthPassword(): string
    {
        return $this->password_hash;
    }

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}