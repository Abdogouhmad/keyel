package com.freesoftware.keyel.quicklock

import android.app.PendingIntent
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.freesoftware.keyel.MainActivity
import com.freesoftware.keyel.R

/**
 * Quick Settings tile that requests a lock with one tap.
 *
 * The tile deliberately does not talk to the Rust session directly. It clears
 * the clipboard and sends the same lock action as the launcher shortcut to
 * MainActivity, which lets the existing Dart lock path do the zeroization.
 */
class KeyelLockTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            label = getString(R.string.quick_lock_tile_label)
            state = Tile.STATE_ACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        LockController.clearClipboard(applicationContext)

        // A PendingIntent from a user tap is an allowed user-initiated launch;
        // no background service or activity start from a service callback.
        val intent = Intent(this, MainActivity::class.java).apply {
            action = LockController.ACTION_LOCK
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        ).send()
    }
}
