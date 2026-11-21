package com.freesoftware.keyel.wear

import android.app.Activity
import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView

/**
 * Standalone code viewer.
 *
 * The watch holds no vault, no clipboard and no service: the app is foreground
 * only, screenshots are blocked with FLAG_SECURE, and codes are masked again as
 * soon as the user leaves. Seeds are read from [TotpStore] only while a code is
 * actually rendered.
 */
class MainActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private var entries: List<WatchEntry> = emptyList()
    private var revealed = false
    private lateinit var adapter: EntryAdapter

    private val ticker = object : Runnable {
        override fun run() {
            if (revealed) adapter.notifyDataSetChanged()
            handler.postDelayed(this, TICK_MS)
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) = reload()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        setContentView(R.layout.activity_main)
        TotpStore.init(applicationContext)

        adapter = EntryAdapter(this)
        findViewById<ListView>(R.id.entries).adapter = adapter
        findViewById<Button>(R.id.reveal).setOnClickListener {
            revealed = !revealed
            (it as Button).setText(if (revealed) R.string.watch_hide else R.string.watch_show)
            adapter.notifyDataSetChanged()
        }
        findViewById<Button>(R.id.clear).setOnClickListener { confirmClear() }
        reload()
    }

    override fun onStart() {
        super.onStart()
        registerReceiver(receiver, IntentFilter(ACTION_CHANGED))
        // Every resume starts masked; revealing is an explicit, local tap.
        revealed = false
        findViewById<Button>(R.id.reveal)?.setText(R.string.watch_show)
        reload()
    }

    override fun onResume() {
        super.onResume()
        handler.post(ticker)
    }

    override fun onPause() {
        handler.removeCallbacks(ticker)
        revealed = false
        adapter.notifyDataSetChanged()
        super.onPause()
    }

    override fun onStop() {
        runCatching { unregisterReceiver(receiver) }
        super.onStop()
    }

    private fun reload() {
        entries = TotpStore.entries()
        adapter.notifyDataSetChanged()
        findViewById<View>(R.id.empty).visibility =
            if (entries.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun confirmClear() {
        AlertDialog.Builder(this)
            .setTitle(R.string.watch_clear_title)
            .setMessage(R.string.watch_clear_message)
            .setNegativeButton(android.R.string.cancel, null)
            .setPositiveButton(R.string.watch_clear) { _, _ ->
                TotpStore.clear()
                revealed = false
                reload()
            }
            .show()
    }

    private inner class EntryAdapter(context: Context) :
        ArrayAdapter<WatchEntry>(context, R.layout.totp_row) {

        override fun getCount(): Int = entries.size

        override fun getItem(position: Int): WatchEntry = entries[position]

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: LayoutInflater.from(context)
                .inflate(R.layout.totp_row, parent, false)
            val entry = getItem(position)
            val label = view.findViewById<TextView>(R.id.label)
            val code = view.findViewById<TextView>(R.id.code)
            label.text = entry.label.ifBlank { context.getString(R.string.watch_app_name) }
            if (!revealed) {
                code.text = context.getString(R.string.watch_hidden)
                return view
            }
            code.text = runCatching {
                val now = System.currentTimeMillis() / 1000
                val value = TotpGenerator.code(
                    entry.secret,
                    entry.digits,
                    entry.period,
                    entry.algorithm,
                    now,
                )
                val left = TotpGenerator.secondsLeft(entry.period, now)
                "$value  ${context.getString(R.string.watch_seconds, left)}"
            }.getOrDefault(context.getString(R.string.watch_error))
            return view
        }
    }

    private companion object {
        const val TICK_MS = 1_000L
        const val ACTION_CHANGED = "com.freesoftware.keyel.wear.TOTP_CHANGED"
    }
}
