<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_conversations', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('type', 16);                 // DIRECT | GROUP
            $table->string('name', 255)->nullable();    // group name; null for DIRECT
            $table->string('avatar_url', 1024)->nullable();
            $table->unsignedBigInteger('last_message_id')->nullable(); // FK added with messages
            $table->timestampTz('last_message_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->index('last_message_at', 'idx_chat_conversations_last_message_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_conversations');
    }
};
