<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

class SecurityRolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            // Dashboard
            'dashboard.view',

            // Finance
            'finance.view',
            'finance.create',
            'finance.update',
            'finance.delete',

            // Health
            'health.view',
            'health.create',
            'health.update',
            'health.delete',

            // Projects
            'projects.view',
            'projects.create',
            'projects.update',
            'projects.delete',

            // AI
            'ai.view',
            'ai.generate',

            // Notifications
            'notifications.view',
            'notifications.manage',

            // Automation
            'automation.view',
            'automation.create',
            'automation.update',
            'automation.delete',

            // Security
            'security.view',
            'security.manage',

            // Admin
            'users.view',
            'users.manage',
            'roles.manage',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate([
                'name' => $permission,
                'guard_name' => 'web',
            ]);
        }

        $admin = Role::firstOrCreate([
            'name' => 'admin',
            'guard_name' => 'web',
        ]);

        $user = Role::firstOrCreate([
            'name' => 'user',
            'guard_name' => 'web',
        ]);

        $viewer = Role::firstOrCreate([
            'name' => 'viewer',
            'guard_name' => 'web',
        ]);

        $admin->syncPermissions($permissions);

        $user->syncPermissions([
            'dashboard.view',

            'finance.view',
            'finance.create',
            'finance.update',

            'health.view',
            'health.create',
            'health.update',

            'projects.view',
            'projects.create',
            'projects.update',

            'ai.view',
            'ai.generate',

            'notifications.view',

            'automation.view',
            'automation.create',
            'automation.update',
        ]);

        $viewer->syncPermissions([
            'dashboard.view',

            'finance.view',
            'health.view',
            'projects.view',
            'ai.view',
            'notifications.view',
            'automation.view',
        ]);

        $firstUser = User::query()->first();

        if ($firstUser && ! $firstUser->hasRole('admin')) {
            $firstUser->assignRole('admin');
        }
    }
}
