<?php

/*
| Broadcast channel authorization. Populated by the Chat module port — defines
| who may listen on conversation, presence, and per-user (inbox / calls)
| channels. Authenticated via the "api" guard (see BroadcastServiceProvider).
|
| Only the private per-user channels need authorization here. The public
| conversation/presence/call channels (conversations.{id},
| conversations.{id}.call, presence) require no auth — membership is enforced
| at the REST layer in the chat services.
*/

use Illuminate\Support\Facades\Broadcast;

// /user/queue/inbox  → user.{userId}.inbox
Broadcast::channel('user.{userId}.inbox', function ($user, $userId) {
    return (int) $user->userId === (int) $userId;
});

// /user/queue/calls  → user.{userId}.calls
Broadcast::channel('user.{userId}.calls', function ($user, $userId) {
    return (int) $user->userId === (int) $userId;
});
