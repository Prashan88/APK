package com.fieldpath.visittracker.data.repository

import com.fieldpath.visittracker.data.model.VisitCard
import kotlinx.coroutines.flow.Flow

interface VisitRepository {
    fun streamVisits(tenantId: String, routeId: String? = null, salesRepId: String? = null): Flow<List<VisitCard>>
    suspend fun createVisit(visit: VisitCard)
    suspend fun updateVisit(visit: VisitCard)
    suspend fun approveVisit(visitId: String, tenantId: String, managerId: String, comment: String?)
}
