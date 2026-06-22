<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_messages', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('conversation_id');
            $table->unsignedBigInteger('sender_id')->nullable();
            $table->string('type', 16);                 // TEXT | IMAGE | VOICE | FILE
            $table->text('body')->nullable();
            $table->string('attachment_url', 1024)->nullable();
            $table->string('attachment_content_type', 64)->nullable();
            $table->bigInteger('attachment_size_bytes')->nullable();
            $table->integer('duration_seconds')->nullable();
            $table->unsignedBigInteger('reply_to_message_id')->nullable();
            $table->timestampTz('edited_at')->nullable();
            $table->timestampTz('deleted_at')->nullable();   // soft delete
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->foreign('conversation_id')->references('id')->on('chat_conversations')->onDelete('cascade');
            $table->foreign('sender_id')->references('id')->on('users')->onDelete('set null');
            $table->foreign('reply_to_message_id')->references('id')->on('chat_messages')->onDelete('set null');
            $table->index(['conversation_id', 'created_at'], 'idx_chat_messages_conv_created');
            $table->index('sender_id', 'idx_chat_messages_sender');
        });

        // Denormalised inbox pointer: chat_conversations.last_message_id -> chat_messages.id
        Schema::table('chat_conversations', function (Blueprint $table) {
            $table->foreign('last_message_id', 'fk_chat_conversations_last_message')
                ->references('id')->on('chat_messages')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('chat_conversations', function (Blueprint $table) {
            $table->dropForeign('fk_chat_conversations_last_message');
        });
        Schema::dropIfExists('chat_messages');
    }
};
