package com.fieldpath.visittracker.data.remote

import android.util.Log
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory



/**
 * Some APIs occasionally return malformed JSON (for example HTML error pages).
 * Gson's lenient mode paired with guarded logging ensures we do not crash while
 * still capturing the server payload for debugging.
 */
object RetrofitProvider {
    private const val BASE_URL = "https://example.com/"
    private const val TAG = "RetrofitProvider"
    private const val MAX_LOG_BYTES = 1024L * 1024L // limit logging to 1MB

    private val safeLoggingInterceptor = Interceptor { chain ->
        val request = chain.request()
        val response = chain.proceed(request)
        return@Interceptor try {
            val peekBody = response.peekBody(MAX_LOG_BYTES)
            Log.d(TAG, "Raw API response for ${'$'}{request.url}: ${'$'}{peekBody.string()}")
            response
        } catch (throwable: Throwable) {
            Log.w(TAG, "Failed to log raw API response", throwable)
            response
        }
    }

    private val httpLoggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BASIC
    }

    private val gson: Gson by lazy {
        GsonBuilder()
            // Allow lenient parsing so unexpected tokens do not crash the app.
            .setLenient()
            .create()
    }

    private val okHttpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .addInterceptor(httpLoggingInterceptor)
            .addInterceptor(safeLoggingInterceptor)
            .build()
    }

    val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    fun createVisitApiService(): VisitApiService = retrofit.create(VisitApiService::class.java)
}
