<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->nullable()->unique();
            $table->string('employee_no', 64)->unique();
            $table->string('full_name', 255);
            $table->string('work_email', 255)->nullable();
            $table->string('phone', 50)->nullable();
            $table->string('position', 128)->nullable();
            $table->string('department', 128)->nullable();
            $table->date('hire_date')->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('gender', 16)->nullable();
            $table->string('address', 1024)->nullable();
            $table->string('avatar_url', 1024)->nullable();
            $table->string('status', 16)->default('ACTIVE');
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
            $table->index('user_id', 'idx_employees_user_id');
            $table->index('full_name', 'idx_employees_full_name');
            $table->index('department', 'idx_employees_department');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
