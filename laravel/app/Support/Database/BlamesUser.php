<?php

namespace App\Support\Database;

use Illuminate\Support\Facades\Auth;

/**
 * Populates the created_by / updated_by audit columns from the authenticated
 * user id — the analogue of Spring Data JPA auditing (AuditorAwareConfig +
 * BaseEntity's @CreatedBy / @LastModifiedBy). created_at / updated_at are
 * handled by Eloquent's own timestamps.
 *
 * Apply to models whose table has created_by / updated_by columns.
 */
trait BlamesUser
{
    public static function bootBlamesUser(): void
    {
        static::creating(function ($model) {
            $id = Auth::guard('api')->id();
            if ($id !== null) {
                if (empty($model->created_by)) {
                    $model->created_by = $id;
                }
                $model->updated_by = $id;
            }
        });

        static::updating(function ($model) {
            $id = Auth::guard('api')->id();
            if ($id !== null) {
                $model->updated_by = $id;
            }
        });
    }
}
