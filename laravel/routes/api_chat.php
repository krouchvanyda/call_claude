<?php

/*
| Chat / voice-video call / presence routes.
| Included from routes/api.php inside the api/v1 + auth group, so every route
| here inherits the /api/v1 prefix and the JWT auth middleware. Chat is open to
| any authenticated user (no chat:read / chat:write gate) per the module spec —
| membership is enforced inside the services.
|
| Paths mirror the Spring @RequestMapping mappings exactly.
*/

use App\Features\Chat\Controllers\ChatCallController;
use App\Features\Chat\Controllers\ConversationController;
use App\Features\Chat\Controllers\MessageController;
use App\Features\Chat\Controllers\PresenceController;
use Illuminate\Support\Facades\Route;

// ---- conversations --------------------------------------------------------
Route::get('chats/conversations', [ConversationController::class, 'index']);
Route::post('chats/conversations', [ConversationController::class, 'store']);
Route::get('chats/conversations/{id}', [ConversationController::class, 'show'])->whereNumber('id');
Route::patch('chats/conversations/{id}', [ConversationController::class, 'update'])->whereNumber('id');
Route::delete('chats/conversations/{id}', [ConversationController::class, 'destroy'])->whereNumber('id');
Route::post('chats/conversations/{id}/members', [ConversationController::class, 'addMembers'])->whereNumber('id');
Route::delete('chats/conversations/{id}/members/{userId}', [ConversationController::class, 'removeMember'])
    ->whereNumber('id')->whereNumber('userId');
Route::post('chats/conversations/{id}/read', [ConversationController::class, 'markRead'])->whereNumber('id');

// ---- messages -------------------------------------------------------------
Route::get('chats/conversations/{convId}/messages', [MessageController::class, 'history'])->whereNumber('convId');
Route::get('chats/conversations/{convId}/messages/search', [MessageController::class, 'search'])->whereNumber('convId');
Route::post('chats/conversations/{convId}/messages', [MessageController::class, 'send'])->whereNumber('convId');
Route::patch('chats/messages/{id}', [MessageController::class, 'edit'])->whereNumber('id');
Route::delete('chats/messages/{id}', [MessageController::class, 'delete'])->whereNumber('id');
Route::post('chats/messages/{id}/reactions', [MessageController::class, 'toggleReaction'])->whereNumber('id');

// ---- calls ----------------------------------------------------------------
Route::get('chats/calls', [ChatCallController::class, 'myHistory']);
// NOTE: declared before /calls/{id} so the literal path is not captured by {id}.
Route::get('chats/calls/stream-token', [ChatCallController::class, 'streamToken']);
Route::get('chats/calls/{id}', [ChatCallController::class, 'show'])->whereNumber('id');
Route::get('chats/conversations/{convId}/calls', [ChatCallController::class, 'conversationHistory'])->whereNumber('convId');
Route::post('chats/conversations/{convId}/calls', [ChatCallController::class, 'start'])->whereNumber('convId');
Route::post('chats/calls/{id}/accept', [ChatCallController::class, 'accept'])->whereNumber('id');
Route::post('chats/calls/{id}/reject', [ChatCallController::class, 'reject'])->whereNumber('id');
Route::post('chats/calls/{id}/end', [ChatCallController::class, 'end'])->whereNumber('id');

// ---- presence -------------------------------------------------------------
Route::get('chats/presence', [PresenceController::class, 'batch']);
Route::post('chats/presence/background', [PresenceController::class, 'background']);
Route::post('chats/presence/foreground', [PresenceController::class, 'foreground']);
Route::get('chats/presence/{userId}', [PresenceController::class, 'show'])->whereNumber('userId');
