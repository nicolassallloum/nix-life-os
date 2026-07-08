<?php

namespace App\Models;

use App\Models\Plan;
use App\Models\Subscription;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles, HasUuids;

    protected $fillable = [
    	'name',
    	'email',
   	'password',
    	'phone',
    	'status',
    	'last_login_at',
    	'last_login_ip',
    	'failed_login_attempts',
	];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
    public function aiRecommendations(): HasMany
    {
        return $this->hasMany(AIRecommendation::class, 'user_id');
    }
    public function todoProjects(): HasMany
    {
        return $this->hasMany(TodoProject::class);
    }

    public function todoTasks(): HasMany
    {
        return $this->hasMany(TodoTask::class);
    }
    public function aiRecommendationFeedback(): HasMany
    {
        return $this->hasMany(AIRecommendationFeedback::class, 'user_id');
    }

    public function aiDailyScores(): HasMany
    {
        return $this->hasMany(AIUserDailyScore::class, 'user_id');
    }
    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscription(): HasOne
    {
        return $this->hasOne(Subscription::class)->where('status', 'active');
    }

    public function currentPlan(): ?Plan
    {
        return $this->activeSubscription?->plan;
    }
}
