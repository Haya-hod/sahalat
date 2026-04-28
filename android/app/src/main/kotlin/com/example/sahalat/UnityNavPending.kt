package com.example.sahalat

/**
 * Holds navigation payload from Flutter until Unity starts and consumes it via JNI
 * (see FlutterBridge.ApplyPendingNavigationFromAndroid in the Unity project).
 */
object UnityNavPending {
    private val lock = Any()
    private var pathJson: String? = null
    private var simplePayload: String? = null

    @JvmStatic
    fun prepareNavigation(pathJsonArg: String?, simplePayloadArg: String?) {
        synchronized(lock) {
            val j = pathJsonArg?.trim()?.takeIf { it.isNotEmpty() }
            pathJson = j
            simplePayload =
                if (j != null) {
                    null
                } else {
                    simplePayloadArg?.trim()?.takeIf { it.isNotEmpty() }
                }
        }
    }

    @JvmStatic
    fun consumePathJson(): String? =
        synchronized(lock) {
            val j = pathJson
            pathJson = null
            if (j != null) simplePayload = null
            j
        }

    @JvmStatic
    fun consumeSimplePath(): String? =
        synchronized(lock) {
            val s = simplePayload
            simplePayload = null
            s
        }
}
