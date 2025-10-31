package com.fieldpath.visittracker.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.fieldpath.visittracker.ui.admin.AdminDashboardScreen
import com.fieldpath.visittracker.ui.manager.ManagerDashboardScreen
import com.fieldpath.visittracker.ui.salesref.SalesRefDashboardScreen

sealed class FieldTrackerDestination(val route: String) {
    data object AdminDashboard : FieldTrackerDestination("admin")
    data object ManagerDashboard : FieldTrackerDestination("manager")
    data object SalesDashboard : FieldTrackerDestination("sales")
}

@Composable
fun FieldTrackerNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(
        navController = navController,
        startDestination = FieldTrackerDestination.AdminDashboard.route
    ) {
        composable(FieldTrackerDestination.AdminDashboard.route) {
            AdminDashboardScreen(onNavigate = navController::navigate)
        }
        composable(FieldTrackerDestination.ManagerDashboard.route) {
            ManagerDashboardScreen(onNavigate = navController::navigate)
        }
        composable(FieldTrackerDestination.SalesDashboard.route) {
            SalesRefDashboardScreen(onNavigate = navController::navigate)
        }
    }
}
