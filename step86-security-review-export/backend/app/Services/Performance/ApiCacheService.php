<?php

namespace App\Services\Performance;

use Illuminate\Support\Facades\Cache;

class ApiCacheService
{
    public static function remember(string $key, callable $callback, ?int $ttl = null)
    {
        $ttl = $ttl ?? (int) env('API_CACHE_TTL', 300);

        return Cache::remember($key, $ttl, $callback);
    }

    public static function forget(string $key): void
    {
        Cache::forget($key);
    }

    public static function forgetByUser(string $prefix, string $userId): void
    {
        Cache::forget($prefix . ':' . $userId);
    }

    public static function userKey(string $module, string $userId, array $params = []): string
    {
        ksort($params);

        return $module . ':' . $userId . ':' . md5(json_encode($params));
    }
}
