package com.fieldpath.visittracker.ui.salesref

import androidx.compose.foundation.layout.Arrangement
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
import com.fieldpath.visittracker.data.model.VisitCard
import com.fieldpath.visittracker.ui.components.spacing

@Composable
fun SalesRefDashboardScreen(onNavigate: (String) -> Unit) {
    val visits by remember {
        mutableStateOf(
            listOf(
                VisitCard.example(id = "visit-3", customerName = "Globex"),
                VisitCard.example(id = "visit-4", customerName = "Initech"),
            )
        )
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.medium)
    ) {
        Text(text = "Sales Rep Visits", style = MaterialTheme.typography.headlineMedium)
        Button(onClick = { /* TODO: open capture workflow */ }) {
            Text(text = "Add Visit Card")
        }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.small)) {
            items(visits) { visit ->
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
