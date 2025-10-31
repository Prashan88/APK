package com.fieldpath.visittracker.data.model

data class Tenant(
    val id: String,
    val name: String,
    val isActive: Boolean = true
)
