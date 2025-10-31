package com.fieldpath.visittracker.data.model

import java.time.Instant

data class VisitCard(
    val id: String,
    val tenantId: String,
    val routeId: String,
    val salesRepId: String,
    val customerId: String,
    val customerName: String,
    val geoPoint: GeoPoint,
    val geoHash: String,
    val summary: String,
    val notes: String,
    val imageUrl: String?,
    val status: VisitStatus,
    val createdAt: Instant,
    val updatedAt: Instant,
    val managerComment: String? = null
) {
    companion object {
        fun example(id: String, customerName: String): VisitCard = VisitCard(
            id = id,
            tenantId = "tenant-sample",
            routeId = "route-1",
            salesRepId = "sales-1",
            customerId = "customer-1",
            customerName = customerName,
            geoPoint = GeoPoint(latitude = 37.422, longitude = -122.084),
            geoHash = "9q9hv",
            summary = "Visited store and verified stock levels",
            notes = "Discussed Q3 targets and promotional materials",
            imageUrl = null,
            status = VisitStatus.PendingReview,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            managerComment = null
        )
    }
}

enum class VisitStatus { Draft, PendingReview, Approved, Rejected }
