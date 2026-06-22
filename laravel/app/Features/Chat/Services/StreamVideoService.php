<?php

namespace App\Features\Chat\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Port of the Spring StreamVideoService. Server-side calls to Stream's Video
 * REST API to ring callees (so their devices receive the VoIP push that raises
 * the native CallKit / ConnectionService incoming-call screen even when the app
 * is backgrounded or killed) and to cancel that ring on call end.
 *
 * Auth reuses the same per-user Stream token the mobile SDK uses (HS256 over the
 * API secret, user_id = caller). Calling get-or-create as the caller makes the
 * caller the Stream creator, so Stream pushes to every other member, not back to
 * the caller. All sends are exception-swallowing — a Stream hiccup must never
 * break call signalling. (The Spring @Async is approximated by swallowing here;
 * callers already invoke this from within transactional flows that ignore the
 * result.)
 */
class StreamVideoService
{
    private const BASE_URL = 'https://video.stream-io-api.com';

    /** @var StreamTokenService */
    private $tokens;

    public function __construct(StreamTokenService $tokens)
    {
        $this->tokens = $tokens;
    }

    /**
     * Fire-and-forget get-or-create of the Stream call with ring: true so the
     * callees' devices receive the VoIP push.
     *
     * @param string|null $streamCallCid type:id CID, e.g. default:erp-call-1220
     * @param int $callerId caller's user id (becomes the Stream creator; not rung)
     * @param iterable<int> $memberUserIds caller + all callees
     */
    public function ring(?string $streamCallCid, int $callerId, $memberUserIds): void
    {
        if (! $this->tokens->isEnabled()) {
            Log::warning('[stream] skip ring — Stream not configured (cid='.$streamCallCid.')');
            return;
        }
        if ($streamCallCid === null || trim($streamCallCid) === '') {
            Log::warning('[stream] skip ring — missing streamCallCid (caller='.$callerId.')');
            return;
        }

        [$type, $id] = $this->splitCid($streamCallCid);

        $seen = [];
        $members = [];
        foreach ($memberUserIds as $uid) {
            $uid = (int) $uid;
            if (isset($seen[$uid])) {
                continue;
            }
            $seen[$uid] = true;
            $members[] = ['user_id' => (string) $uid];
        }

        // ring is top-level; members live under data. Caller token => caller is
        // the creator, so created_by_id is implicit and must NOT be sent.
        $body = [
            'ring' => true,
            'data' => ['members' => $members],
        ];

        $token = $this->tokens->issueFor($callerId);
        $apiKey = (string) config('erp.stream.api_key');

        try {
            Http::withHeaders([
                'Authorization' => $token['token'],
                'stream-auth-type' => 'jwt',
            ])->post(self::BASE_URL.'/api/v2/video/call/'.$type.'/'.$id.'?api_key='.urlencode($apiKey), $body);
            Log::info('[stream] rang call cid='.$streamCallCid.' caller='.$callerId.' members='.count($members));
        } catch (Throwable $ex) {
            Log::warning('[stream] ring error cid='.$streamCallCid.': '.$ex->getMessage());
        }
    }

    /**
     * Fire-and-forget end of the Stream call (mark_ended) so a still-ringing
     * callee's device stops ringing. A 404/400 here is harmless — it just means
     * the call was never created on Stream (e.g. all callees were online so
     * ring() was skipped).
     *
     * @param string|null $streamCallCid type:id CID
     * @param int $callerId the call creator (their token carries the end-call capability)
     */
    public function endCall(?string $streamCallCid, int $callerId): void
    {
        if (! $this->tokens->isEnabled()) {
            Log::warning('[stream] skip end — Stream not configured (cid='.$streamCallCid.')');
            return;
        }
        if ($streamCallCid === null || trim($streamCallCid) === '') {
            Log::warning('[stream] skip end — missing streamCallCid (caller='.$callerId.')');
            return;
        }

        [$type, $id] = $this->splitCid($streamCallCid);

        $token = $this->tokens->issueFor($callerId);
        $apiKey = (string) config('erp.stream.api_key');

        try {
            Http::withHeaders([
                'Authorization' => $token['token'],
                'stream-auth-type' => 'jwt',
            ])->post(self::BASE_URL.'/api/v2/video/call/'.$type.'/'.$id.'/mark_ended?api_key='.urlencode($apiKey), (object) []);
            Log::info('[stream] ended call cid='.$streamCallCid.' caller='.$callerId);
        } catch (Throwable $ex) {
            Log::warning('[stream] end error cid='.$streamCallCid.': '.$ex->getMessage());
        }
    }

    /**
     * "default:erp-call-1220" -> ["default", "erp-call-1220"].
     *
     * @return array{0:string,1:string}
     */
    private function splitCid(string $cid): array
    {
        $sep = strpos($cid, ':');
        if ($sep === false || $sep <= 0) {
            return ['default', $cid];
        }
        return [substr($cid, 0, $sep), substr($cid, $sep + 1)];
    }
}
