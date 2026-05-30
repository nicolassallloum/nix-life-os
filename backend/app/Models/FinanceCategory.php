<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FinanceCategory extends Model
{
    use HasFactory;

    protected $table = 'nix_life_os.finance_category';

    protected $primaryKey = 'id';

    public $incrementing = true;

    protected $keyType = 'int';

    protected $fillable = [
        'user_id',
        'name',
        'type',
        'icon',
        'color',
        'status',
    ];

    protected $casts = [
        'id' => 'integer',
        'user_id' => 'integer',
    ];
}