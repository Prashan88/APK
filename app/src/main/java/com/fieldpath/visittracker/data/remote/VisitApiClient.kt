package com.fieldpath.visittracker.data.remote

import android.util.Log
import com.google.gson.JsonSyntaxException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException

class VisitApiClient(
    private val service: VisitApiService,
) {

    suspend fun fetchVisits(): Result<List<VisitDto>> = withContext(Dispatchers.IO) {
        try {
            val response = service.getVisits()

            runCatching {
                response.raw().peekBody(MAX_LOG_BYTES).string()
            }.onSuccess { raw ->
                Log.d(TAG, "Raw response content: ${'$'}raw")
            }.onFailure { throwable ->
                Log.w(TAG, "Unable to peek response body", throwable)
            }

            if (response.isSuccessful) {
                val body = response.body()
                if (body != null) {
                    Result.success(body)
                } else {
                    Log.w(TAG, "Response was successful but contained no data")
                    Result.success(emptyList())
                }
            } else {
                val errorMessage = response.errorBody()?.string().orEmpty()
                Log.w(TAG, "Request failed with ${'$'}{response.code()}: ${'$'}errorMessage")
                Result.failure(IllegalStateException("Request failed with HTTP ${'$'}{response.code()}"))
            }
        } catch (exception: JsonSyntaxException) {
            Log.e(TAG, "Malformed JSON response", exception)
            Result.failure(exception)
        } catch (exception: IOException) {
            Log.e(TAG, "Network request failed", exception)
            Result.failure(exception)
        } catch (exception: HttpException) {
            Log.e(TAG, "HTTP exception during request", exception)
            Result.failure(exception)
        }
    }

    companion object {
        private const val TAG = "VisitApiClient"
        private const val MAX_LOG_BYTES = 1024L * 256L
    }
}
