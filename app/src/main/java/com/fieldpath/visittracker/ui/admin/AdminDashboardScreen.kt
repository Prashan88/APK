package com.fieldpath.visittracker.ui.admin

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.fieldpath.visittracker.data.model.DashboardAction
import com.fieldpath.visittracker.ui.navigation.FieldTrackerDestination

@Composable
fun AdminDashboardScreen(onNavigate: (String) -> Unit) {
    val actions by remember {
        mutableStateOf(
            listOf(
                DashboardAction("Add Customer", "Create and manage customers across tenants"),
                DashboardAction("Add Route", "Manage geo-optimized visit routes"),
                DashboardAction("Add Manager", "Invite and manage manager users"),
                DashboardAction("Add Sales Rep", "Provision sales representatives with route access"),
                DashboardAction("Review Tenants", "Switch tenants and manage global settings"),
            )
        )
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = "Admin Console",
            style = MaterialTheme.typography.headlineMedium,
        )
        LazyColumn {
            items(actions) { action ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Column {
                        Text(text = action.title, style = MaterialTheme.typography.titleMedium)
                        Text(text = action.description, style = MaterialTheme.typography.bodyMedium)
                        Button(onClick = { onNavigate(FieldTrackerDestination.ManagerDashboard.route) }) {
                            Text(text = "Open")
                        }
                    }
                }
            }
        }
    }
}
