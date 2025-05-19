-- Order Tracking Schema

-- Create order_tracking table
CREATE TABLE IF NOT EXISTS order_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'processing',
  estimated_delivery TIMESTAMP WITH TIME ZONE NOT NULL,
  last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  current_location JSONB NOT NULL,
  destination_location JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create tracking_updates table for tracking history
CREATE TABLE IF NOT EXISTS tracking_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tracking_id UUID NOT NULL REFERENCES order_tracking(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL,
  description TEXT NOT NULL,
  location JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create RLS policies
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_updates ENABLE ROW LEVEL SECURITY;

-- Only allow users to view their own tracking information
CREATE POLICY "Users can view their own order tracking"
  ON order_tracking
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow service roles to insert/update tracking data
CREATE POLICY "Service role can manage all order tracking"
  ON order_tracking
  USING (auth.role() = 'service_role');

-- Only allow users to view their own tracking updates
CREATE POLICY "Users can view their tracking updates"
  ON tracking_updates
  FOR SELECT
  USING (
    tracking_id IN (
      SELECT id FROM order_tracking WHERE user_id = auth.uid()
    )
  );

-- Allow service roles to insert/update tracking updates
CREATE POLICY "Service role can manage all tracking updates"
  ON tracking_updates
  USING (auth.role() = 'service_role');

-- Create a function to automatically create tracking record when an order is placed
CREATE OR REPLACE FUNCTION create_order_tracking()
RETURNS TRIGGER AS $$
BEGIN
  -- Create a default tracking record
  INSERT INTO order_tracking (
    order_id,
    user_id,
    status,
    estimated_delivery,
    current_location,
    destination_location
  ) VALUES (
    NEW.id,
    NEW.user_id,
    'processing',
    NOW() + INTERVAL '3 days',
    '{"latitude": 30.0444, "longitude": 31.2357}', -- Cairo coordinates as default warehouse
    '{"latitude": 30.0504, "longitude": 31.2088}'  -- Default delivery location (should be based on shipping address)
  ) RETURNING id INTO NEW.tracking_id;
  
  -- Create initial tracking update
  INSERT INTO tracking_updates (
    tracking_id,
    status,
    description
  ) VALUES (
    NEW.tracking_id,
    'Order Placed',
    'Your order has been received and is being processed.'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger on orders table to create tracking
CREATE TRIGGER create_tracking_on_order_insert
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION create_order_tracking();

-- Create function to update tracking when order status changes
CREATE OR REPLACE FUNCTION update_order_tracking()
RETURNS TRIGGER AS $$
BEGIN
  -- Only run if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;
  
  -- Update the tracking status
  UPDATE order_tracking
  SET status = NEW.status,
      last_updated = NOW()
  WHERE order_id = NEW.id;
  
  -- Add a tracking update
  INSERT INTO tracking_updates (
    tracking_id,
    status,
    description
  ) 
  SELECT 
    id,
    CASE
      WHEN NEW.status = 'processing' THEN 'Order Processing'
      WHEN NEW.status = 'shipped' THEN 'Order Shipped'
      WHEN NEW.status = 'out_for_delivery' THEN 'Out for Delivery'
      WHEN NEW.status = 'delivered' THEN 'Order Delivered'
      WHEN NEW.status = 'cancelled' THEN 'Order Cancelled'
      ELSE NEW.status
    END,
    CASE
      WHEN NEW.status = 'processing' THEN 'Your order is being prepared for shipping.'
      WHEN NEW.status = 'shipped' THEN 'Your order has been shipped and is on its way.'
      WHEN NEW.status = 'out_for_delivery' THEN 'Your order is out for delivery and will arrive soon.'
      WHEN NEW.status = 'delivered' THEN 'Your order has been delivered successfully.'
      WHEN NEW.status = 'cancelled' THEN 'Your order has been cancelled.'
      ELSE 'Status updated to ' || NEW.status
    END
  FROM order_tracking
  WHERE order_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger on orders table for status updates
CREATE TRIGGER update_tracking_on_order_update
AFTER UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION update_order_tracking();

-- Create sample data for testing
DO $$
DECLARE
  tracking_id UUID;
BEGIN
  -- Only create test data if there are no tracking records
  IF (SELECT COUNT(*) FROM order_tracking) = 0 THEN
    -- Create a sample update for a random order
    FOR order_row IN (SELECT id, user_id FROM orders LIMIT 3) LOOP
      -- Create tracking record
      INSERT INTO order_tracking (
        order_id,
        user_id,
        status,
        estimated_delivery,
        current_location,
        destination_location
      ) VALUES (
        order_row.id,
        order_row.user_id,
        'shipped',
        NOW() + INTERVAL '2 days',
        '{"latitude": 30.0444, "longitude": 31.2357}',
        '{"latitude": 30.0504, "longitude": 31.2088}'
      ) RETURNING id INTO tracking_id;
      
      -- Create tracking updates with history
      INSERT INTO tracking_updates (
        tracking_id,
        timestamp,
        status,
        description,
        location
      ) VALUES
      (
        tracking_id,
        NOW() - INTERVAL '2 days',
        'Order Placed',
        'Your order has been received and is being processed.',
        '{"latitude": 30.0444, "longitude": 31.2357}'
      ),
      (
        tracking_id,
        NOW() - INTERVAL '1 day',
        'Order Processing',
        'Your order is being prepared for shipping.',
        '{"latitude": 30.0444, "longitude": 31.2357}'
      ),
      (
        tracking_id,
        NOW() - INTERVAL '12 hours',
        'Order Shipped',
        'Your order has been shipped and is on its way.',
        '{"latitude": 30.0450, "longitude": 31.2370}'
      );
    END LOOP;
  END IF;
END;
$$; 