package com.fieldpath.visittracker.data.source

object FirestorePaths {
    fun tenantDoc(tenantId: String) = "tenants/$tenantId"
    fun tenantCollection() = "tenants"
    fun customersCollection(tenantId: String) = "${tenantDoc(tenantId)}/customers"
    fun routesCollection(tenantId: String) = "${tenantDoc(tenantId)}/routes"
    fun managersCollection(tenantId: String) = "${tenantDoc(tenantId)}/managers"
    fun salesRepsCollection(tenantId: String) = "${tenantDoc(tenantId)}/salesReps"
    fun visitsCollection(tenantId: String) = "${tenantDoc(tenantId)}/visits"
    fun visitDoc(tenantId: String, visitId: String) = "${visitsCollection(tenantId)}/$visitId"
}
