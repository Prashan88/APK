package com.fieldpath.visittracker.ui.manager

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.fieldpath.visittracker.data.model.VisitCard
import com.fieldpath.visittracker.ui.components.spacing

@Composable
fun ManagerDashboardScreen(onNavigate: (String) -> Unit) {
    val pendingVisits by remember {
        mutableStateOf(
            listOf(
                VisitCard.example(id = "visit-1", customerName = "Acme Retail"),
                VisitCard.example(id = "visit-2", customerName = "Northwind Traders"),
            )
        )
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.medium)
    ) {
        Text(text = "Manager Review Queue", style = MaterialTheme.typography.headlineMedium)
        LazyColumn(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.small)) {
            items(pendingVisits) { visit ->
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
                    Column(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.small)) {
                        Text(text = visit.customerName, style = MaterialTheme.typography.titleMedium)
                        Text(text = visit.summary, style = MaterialTheme.typography.bodyMedium)
                        Text(text = "Geo PIN: ${visit.geoHash}")
                    }
                }
            }
        }
    }
}
