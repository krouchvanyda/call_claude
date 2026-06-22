<?php

namespace App\Features\Users\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property string $code
 * @property string|null $description
 */
class Permission extends Model
{
    use BlamesUser;

    protected $table = 'permissions';

    protected $fillable = ['code', 'description'];
}
