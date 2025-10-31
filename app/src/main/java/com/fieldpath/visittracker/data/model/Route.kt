package com.fieldpath.visittracker.data.model

data class Route(
    val id: String,
    val tenantId: String,
    val name: String,
    val customerIds: List<String>,
    val managerIds: List<String> = emptyList(),
    val salesRepIds: List<String> = emptyList()
)
