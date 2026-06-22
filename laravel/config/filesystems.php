<?php

return [

    'default' => env('FILESYSTEM_DRIVER', 'local'),

    'cloud' => env('FILESYSTEM_CLOUD', 's3'),

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root' => storage_path('app'),
        ],

        'public' => [
            'driver' => 'local',
            'root' => storage_path('app/public'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
        ],

        /*
        | Employee avatars are stored on the API host's filesystem and served
        | back as static files, matching the original UPLOAD_AVATAR_DIR /
        | UPLOAD_AVATAR_PUBLIC_BASE_URL behaviour.
        */
        'avatars' => [
            'driver' => 'local',
            'root' => env('UPLOAD_AVATAR_DIR', base_path('uploads/avatars')),
            'url' => env('UPLOAD_AVATAR_PUBLIC_BASE_URL', '/uploads/avatars'),
            'visibility' => 'public',
        ],

    ],

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];
