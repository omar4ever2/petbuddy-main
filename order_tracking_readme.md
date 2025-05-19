# Order Tracking Feature

This document explains how to use and test the order tracking functionality in the PetBuddy app.

## Features

- Real-time tracking of order status
- Visual map showing the current location of the order
- Timeline of order status updates
- Estimation of delivery date

## Database Setup

Before using the tracking feature, make sure the database tables are set up:

1. Run the `setup_tracking_tables.dart` script:
   ```
   dart lib/scripts/setup_tracking_tables.dart
   ```

2. Alternatively, run the full database setup including tracking tables:
   ```
   dart lib/scripts/setup_database.dart
   ```

## Testing the Feature

The tracking page includes testing tools that let you:

1. Manually update the order status (for demo purposes)
2. Simulate movement of the package toward the destination

### Order Statuses

Orders can have the following statuses:
- `processing`: Order is being processed in the warehouse
- `shipped`: Order has been shipped and is in transit
- `out_for_delivery`: Order is out for final delivery
- `delivered`: Order has been delivered successfully
- `cancelled`: Order has been cancelled

## Accessing the Tracking Page

Users can access the tracking page from:
1. The order confirmation page after placing an order
2. The order history page by tapping on the "Track" button for an order
3. The order details modal by tapping on "Track Order"

## Implementation Details

### Tables

The feature uses two tables:
- `order_tracking`: Stores the main tracking information for each order
- `tracking_updates`: Stores the history of status changes and location updates

### Automatic Updates

The database automatically:
1. Creates a tracking record when an order is placed
2. Updates the tracking information when an order status changes
3. Adds entries to the tracking history

### API Methods

The SupabaseService class includes methods for:
- `getOrderTracking(orderId)`: Get all tracking data for an order
- `updateOrderStatus(orderId, newStatus)`: Update an order's status
- `addTrackingUpdate(orderId, status, description)`: Add a custom update
- `updateOrderLocation(orderId, latitude, longitude)`: Update the current location

## Map Integration

The tracking page uses Google Maps to display:
- The current location of the order
- The destination location
- The path of the order so far
- Previous tracking points 