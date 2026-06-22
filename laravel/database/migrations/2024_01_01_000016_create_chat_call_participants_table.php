<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_call_participants', function (Blueprint $table) {
            $table->unsignedBigInteger('call_id');
            $table->unsignedBigInteger('user_id');
            $table->string('status', 16)->default('RINGING'); // RINGING | ANSWERED | REJECTED | LEFT | MISSED
            $table->timestampTz('joined_at')->nullable();
            $table->timestampTz('left_at')->nullable();

            $table->primary(['call_id', 'user_id']);
            $table->foreign('call_id')->references('id')->on('chat_calls')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->index('user_id', 'idx_chat_call_participants_user');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_call_participants');
    }
};
