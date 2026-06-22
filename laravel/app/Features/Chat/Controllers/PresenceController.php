<?php

namespace App\Features\Chat\Controllers;

use App\Features\Chat\Services\PresenceService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PresenceController extends Controller
{
    /** @var PresenceService */
    private $presence;

    public function __construct(PresenceService $presence)
    {
        $this->presence = $presence;
    }

    /** Get one user's current presence (ONLINE / BUSY / OFFLINE + lastSeenAt). */
    public function show(int $userId)
    {
        return $this->presence->dtoOf($userId);
    }

    /**
     * Batch presence for a comma-separated list of user ids (?ids=1,2,3); no
     * `ids` param = the whole snapshot.
     */
    public function batch(Request $request)
    {
        $ids = $request->query('ids');
        if ($ids === null || trim((string) $ids) === '') {
            return $this->presence->snapshot();
        }
        $parsed = [];
        foreach (explode(',', (string) $ids) as $part) {
            $part = trim($part);
            if ($part !== '') {
                $parsed[] = (int) $part;
            }
        }
        if (empty($parsed)) {
            return $this->presence->snapshot();
        }
        return $this->presence->dtosFor($parsed);
    }

    /**
     * App-lifecycle beacon: the caller minimized → mark them OFFLINE now so an
     * incoming call rings their device via VoIP/CallKit instead of being
     * skipped as "online".
     */
    public function background()
    {
        $me = (int) Auth::guard('api')->id();
        $this->presence->markBackgrounded($me);
        return null;
    }

    /** App-lifecycle beacon: the caller returned to the foreground. */
    public function foreground()
    {
        $me = (int) Auth::guard('api')->id();
        $this->presence->clearBackgrounded($me);
        return null;
    }
}
