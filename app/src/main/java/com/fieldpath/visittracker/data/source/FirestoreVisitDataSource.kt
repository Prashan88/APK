package com.fieldpath.visittracker.data.source

import com.fieldpath.visittracker.data.model.VisitCard
import com.fieldpath.visittracker.data.model.VisitStatus
import com.fieldpath.visittracker.data.repository.VisitRepository
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.time.Instant

class FirestoreVisitDataSource(
    private val firestore: FirebaseFirestore
) : VisitRepository {

    override fun streamVisits(
        tenantId: String,
        routeId: String?,
        salesRepId: String?
    ): Flow<List<VisitCard>> = callbackFlow {
        var query = firestore
            .collection("tenants")
            .document(tenantId)
            .collection("visits")

        if (routeId != null) {
            query = query.whereEqualTo("routeId", routeId)
        }
        if (salesRepId != null) {
            query = query.whereEqualTo("salesRepId", salesRepId)
        }

        val registration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            val visits = snapshot?.documents?.mapNotNull { doc ->
                doc.toObject(FirestoreVisit::class.java)?.toDomain(doc.id, tenantId)
            } ?: emptyList()

            trySend(visits)
        }

        awaitClose { registration.remove() }
    }

    override suspend fun createVisit(visit: VisitCard) {
        firestore
            .collection("tenants")
            .document(visit.tenantId)
            .collection("visits")
            .document(visit.id)
            .set(FirestoreVisit.fromDomain(visit))
            .await()
    }

    override suspend fun updateVisit(visit: VisitCard) {
        firestore
            .collection("tenants")
            .document(visit.tenantId)
            .collection("visits")
            .document(visit.id)
            .set(FirestoreVisit.fromDomain(visit))
            .await()
    }

    override suspend fun approveVisit(visitId: String, tenantId: String, managerId: String, comment: String?) {
        firestore
            .collection("tenants")
            .document(tenantId)
            .collection("visits")
            .document(visitId)
            .update(
                mapOf(
                    "status" to VisitStatus.Approved.name,
                    "managerComment" to comment,
                    "approvedBy" to managerId,
                    "updatedAt" to Instant.now().toEpochMilli()
                )
            )
            .await()
    }

    data class FirestoreVisit(
        val tenantId: String = "",
        val routeId: String = "",
        val salesRepId: String = "",
        val customerId: String = "",
        val customerName: String = "",
        val latitude: Double = 0.0,
        val longitude: Double = 0.0,
        val geoHash: String = "",
        val summary: String = "",
        val notes: String = "",
        val imageUrl: String? = null,
        val status: String = VisitStatus.Draft.name,
        val managerComment: String? = null,
        val createdAt: Long = 0,
        val updatedAt: Long = 0
    ) {
        fun toDomain(id: String, tenantId: String): VisitCard = VisitCard(
            id = id,
            tenantId = tenantId,
            routeId = routeId,
            salesRepId = salesRepId,
            customerId = customerId,
            customerName = customerName,
            geoPoint = com.fieldpath.visittracker.data.model.GeoPoint(latitude, longitude),
            geoHash = geoHash,
            summary = summary,
            notes = notes,
            imageUrl = imageUrl,
            status = VisitStatus.valueOf(status),
            createdAt = Instant.ofEpochMilli(createdAt),
            updatedAt = Instant.ofEpochMilli(updatedAt),
            managerComment = managerComment
        )

        companion object {
            fun fromDomain(visit: VisitCard): FirestoreVisit = FirestoreVisit(
                tenantId = visit.tenantId,
                routeId = visit.routeId,
                salesRepId = visit.salesRepId,
                customerId = visit.customerId,
                customerName = visit.customerName,
                latitude = visit.geoPoint.latitude,
                longitude = visit.geoPoint.longitude,
                geoHash = visit.geoHash,
                summary = visit.summary,
                notes = visit.notes,
                imageUrl = visit.imageUrl,
                status = visit.status.name,
                managerComment = visit.managerComment,
                createdAt = visit.createdAt.toEpochMilli(),
                updatedAt = visit.updatedAt.toEpochMilli()
            )
        }
    }
}
