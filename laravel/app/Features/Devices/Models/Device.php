<?php

namespace App\Features\Devices\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * Maps a user to one or more FCM device tokens. Upserts on (user_id, device_id)
 * so token rotation overwrites in place. Port of the Spring Device entity.
 *
 * @property int $id
 * @property int $user_id
 * @property string $device_id
 * @property string $fcm_token
 * @property string $platform
 * @property string|null $app_version
 */
class Device extends Model
{
    use BlamesUser;

    protected $table = 'devices';

    protected $fillable = ['user_id', 'device_id', 'fcm_token', 'platform', 'app_version'];
}
