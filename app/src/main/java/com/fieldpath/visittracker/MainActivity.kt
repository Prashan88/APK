package com.fieldpath.visittracker

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.fieldpath.visittracker.ui.components.LocalSpacing
import com.fieldpath.visittracker.ui.components.Spacing
import com.fieldpath.visittracker.ui.navigation.FieldTrackerNavHost

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            FieldVisitTrackerApp()
        }
    }
}

@Composable
fun FieldVisitTrackerApp() {
    CompositionLocalProvider(LocalSpacing provides Spacing()) {
        MaterialTheme {
            Surface(modifier = Modifier) {
                FieldTrackerNavHost()
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun FieldVisitTrackerAppPreview() {
    FieldVisitTrackerApp()
}
