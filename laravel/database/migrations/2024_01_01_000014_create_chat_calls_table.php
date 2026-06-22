<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_calls', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('conversation_id');
            $table->unsignedBigInteger('caller_id')->nullable();
            $table->string('type', 16);                          // VOICE | VIDEO
            $table->string('status', 16)->default('RINGING');    // RINGING | ANSWERED | ENDED | MISSED | REJECTED | BUSY
            $table->timestampTz('started_at')->useCurrent();
            $table->timestampTz('answered_at')->nullable();
            $table->timestampTz('ended_at')->nullable();
            $table->integer('duration_seconds')->nullable();
            $table->string('end_reason', 64)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->foreign('conversation_id')->references('id')->on('chat_conversations')->onDelete('cascade');
            $table->foreign('caller_id')->references('id')->on('users')->onDelete('set null');
            $table->index(['conversation_id', 'started_at'], 'idx_chat_calls_conv_started');
            $table->index(['caller_id', 'started_at'], 'idx_chat_calls_caller');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_calls');
    }
};
