<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medications')) {
            return;
        }

        $column = DB::selectOne("
            SELECT data_type, udt_name
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = 'health_medications'
              AND column_name = 'user_id'
        ");

        if (! $column || $column->udt_name === 'uuid') {
            return;
        }

        DB::statement('ALTER TABLE health_medications DROP CONSTRAINT IF EXISTS health_medications_user_id_foreign');
        DB::statement('ALTER TABLE health_medications DROP CONSTRAINT IF EXISTS health_medications_user_id_foreign_foreign');

        DB::statement('ALTER TABLE health_medications ALTER COLUMN user_id DROP DEFAULT');
        DB::statement('ALTER TABLE health_medications ALTER COLUMN user_id TYPE uuid USING NULL');

        DB::statement('ALTER TABLE health_medications ADD CONSTRAINT health_medications_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
    }

    public function down(): void
    {
        // Safe production repair migration: do not convert UUID user references back to bigint.
    }
};
