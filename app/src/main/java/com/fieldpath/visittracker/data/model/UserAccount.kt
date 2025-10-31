package com.fieldpath.visittracker.data.model

enum class UserRole { ADMIN, MANAGER, SALES_REP }

data class UserAccount(
    val id: String,
    val tenantId: String,
    val email: String,
    val displayName: String,
    val role: UserRole,
    val assignedRouteIds: List<String> = emptyList(),
)
