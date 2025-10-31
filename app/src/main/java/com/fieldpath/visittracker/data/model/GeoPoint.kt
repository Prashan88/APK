package com.fieldpath.visittracker.data.model

import com.google.firebase.firestore.GeoPoint as FirestoreGeoPoint

data class GeoPoint(
    val latitude: Double,
    val longitude: Double
) {
    val toFirestore: FirestoreGeoPoint
        get() = FirestoreGeoPoint(latitude, longitude)

    companion object {
        fun fromFirestore(point: FirestoreGeoPoint) = GeoPoint(point.latitude, point.longitude)
    }
}
