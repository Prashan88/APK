# Field Visit Tracker Architecture

## Overview
The Field Visit Tracker Android application is built with a modular MVVM architecture and Firebase as the backend. The first iteration focuses on establishing a maintainable code structure, multi-tenant data model, and role-driven navigation skeleton for Admin, Manager, and Sales Representative personas.

## Module Layout
```
app/
 ├─ src/main/java/com/fieldpath/visittracker/
 │   ├─ data/
 │   │   ├─ model/        # Firestore DTOs and domain models
 │   │   ├─ repository/   # Repository interfaces
 │   │   └─ source/       # Firebase data source implementations
 │   ├─ ui/
 │   │   ├─ admin/        # Admin dashboard and flows
 │   │   ├─ manager/      # Manager review interfaces
 │   │   ├─ salesref/     # Sales rep capture flows
 │   │   ├─ components/   # Shared Compose UI building blocks
 │   │   └─ navigation/   # Navigation graph definitions
 │   └─ MainActivity.kt   # Single-activity Compose host
 └─ res/                  # XML resources (themes, strings, etc.)
```

## Multi-Tenant Firestore Layout
Collections are namespaced by tenant so that every document lives under the relevant tenant node. This enables horizontal scaling and easy enforcement of Firestore security rules per tenant.

```
tenants/{tenantId}
  ├─ profile (document)
  ├─ customers/{customerId}
  ├─ routes/{routeId}
  ├─ managers/{managerId}
  ├─ salesReps/{salesRepId}
  └─ visits/{visitId}
```

### Visit Card Document Schema
| Field           | Type      | Description |
|-----------------|-----------|-------------|
| `tenantId`      | string    | Redundant tenant reference used in queries and rules |
| `routeId`       | string    | Route assigned for the visit |
| `salesRepId`    | string    | Owner of the visit card |
| `customerId`    | string    | Customer visited |
| `customerName`  | string    | Denormalized to simplify lookups |
| `latitude`      | double    | Latitude captured at visit creation |
| `longitude`     | double    | Longitude captured at visit creation |
| `geoHash`       | string    | Geohash for efficient geospatial queries |
| `summary`       | string    | Short summary of the visit |
| `notes`         | string    | Detailed notes |
| `imageUrl`      | string?   | Reference to Firebase Storage asset |
| `status`        | string    | Draft / PendingReview / Approved / Rejected |
| `managerComment`| string?   | Optional feedback from manager |
| `createdAt`     | timestamp | Epoch millis for creation |
| `updatedAt`     | timestamp | Epoch millis for last change |
| `approvedBy`    | string?   | Manager approver reference |

### Security Rule Considerations
* Sales reps read/write visit cards in their tenant. Writes are limited to visits they own.
* Managers can update status and comments for visits within assigned routes.
* Admins can manage tenant-scoped collections and invite users.
* All documents must assert the `tenantId` field and security rules should validate it against the path segment to prevent data leakage across tenants.

## Role-Specific UX
* **Admin**: Manage customers, routes, user provisioning, and tenant configuration. A card-based dashboard surfaces primary management tasks.
* **Manager**: Review visit submissions, approve or reject with comments, and monitor route progress.
* **Sales Rep**: Capture new visit cards with geolocation, photo upload, and notes. Pending submissions display within a list.

## Next Steps
1. Integrate Firebase Authentication to support tenant-aware logins and role resolution.
2. Implement real Firestore repository bindings with Hilt dependency injection.
3. Build visit creation workflow including camera/gallery integration and live location capture.
4. Define Firestore security rules and indexes for multitenancy enforcement.
