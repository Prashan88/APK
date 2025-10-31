package com.fieldpath.visittracker.data.model

data class Customer(
    val id: String,
    val tenantId: String,
    val name: String,
    val address: String,
    val geoFence: List<GeoPoint> = emptyList()
)
