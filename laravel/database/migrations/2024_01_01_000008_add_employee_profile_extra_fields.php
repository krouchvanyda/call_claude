<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->timestampTz('last_login_at')->nullable();
            $table->string('emergency_contact', 255)->nullable();
            $table->string('emergency_phone', 50)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropColumn(['last_login_at', 'emergency_contact', 'emergency_phone']);
        });
    }
};
