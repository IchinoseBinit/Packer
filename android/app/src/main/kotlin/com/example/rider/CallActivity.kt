package com.np.dropit.packer

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.Toast

class CallActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

        // 🔥 Request to unlock the screen (some devices require this)
        keyguardManager.requestDismissKeyguard(this, null)

        // 🔥 Ensure the activity appears on top of the lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        setContentView(R.layout.activity_call_screen)

        val callerName = findViewById<TextView>(R.id.callerName)
        val btnAnswer = findViewById<Button>(R.id.btnAnswer)

        callerName.text = "Incoming Call from John Doe"

        btnAnswer.setOnClickListener {
            Toast.makeText(this, "Call Accepted", Toast.LENGTH_SHORT).show()

            // 🔥 Notify Flutter that call is accepted
            MainActivity.callAccepted()

            finish()  // Close CallActivity
        }
    }
}
