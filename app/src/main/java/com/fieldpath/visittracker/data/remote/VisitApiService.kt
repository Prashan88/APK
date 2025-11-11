package com.fieldpath.visittracker.data.remote

import retrofit2.Response
import retrofit2.http.GET

interface VisitApiService {
    @GET("visits")
    suspend fun getVisits(): Response<List<VisitDto>>
}
