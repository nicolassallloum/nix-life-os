<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing CORS Configuration
    |--------------------------------------------------------------------------
    |
    | Frontend local dev:
    | http://127.0.0.1:5173
    | http://localhost:5173
    |
    | Production frontend:
    | https://app.nixlifeos.com
    |
    */

    'paths' => [
        'api/*',
        'sanctum/csrf-cookie',
    ],

    'allowed_methods' => [
        '*',
    ],

    'allowed_origins' => [
        'http://127.0.0.1:5173',
        'http://localhost:5173',
        'http://127.0.0.1',
        'http://localhost',
        'https://app.nixlifeos.com',
        'https://nixlifeos.com',
        'https://www.nixlifeos.com',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        '*',
    ],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];