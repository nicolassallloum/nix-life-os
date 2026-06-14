<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_alerts')) {
            return;
        }

        $column = DB::selectOne("
            SELECT udt_name
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = 'health_alerts'
              AND column_name = 'source_id'
        ");

        if (! $column || $column->udt_name !== 'uuid') {
            return;
        }

        DB::statement('ALTER TABLE health_alerts ALTER COLUMN source_id TYPE varchar(191) USING source_id::text');
    }

    public function down(): void
    {
        // Safe production repair: source_id may reference bigint or uuid source tables.
        // Do not convert back to uuid.
    }
};
