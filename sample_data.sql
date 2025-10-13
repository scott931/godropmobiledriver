-- Sample Data for GoDrop Fleet Management System
USE godrop_db;

-- Additional users
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active, email_verified) VALUES
('manager@godrop.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Manager', 'manager', TRUE, TRUE),
('driver1@godrop.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mike', 'Johnson', 'driver', TRUE, TRUE);

-- Additional schools
INSERT INTO schools (name, address, phone, email, principal_name, school_type) VALUES
('Central Middle School', '456 Learning Ave, City, State 12345', '555-234-5678', 'info@central.edu', 'Dr. Michael Johnson', 'middle');

-- Drivers
INSERT INTO drivers (driver_id, user_id, first_name, last_name, date_of_birth, license_number, license_expiry, phone, email, address, emergency_contact_name, emergency_contact_phone, hire_date, status) VALUES
('DRV001', 3, 'Mike', 'Johnson', '1985-03-15', 'DL123456789', '2025-03-15', '555-111-2222', 'driver1@godrop.com', '123 Driver St, City, State 12345', 'Mary Johnson', '555-111-3333', '2023-01-15', 'active');

-- Vehicles
INSERT INTO vehicles (vehicle_id, license_plate, make, model, year, color, capacity, fuel_type, transmission, vin, registration_expiry, insurance_expiry, status, current_mileage, last_maintenance_date, next_maintenance_date) VALUES
('VEH001', 'ABC123', 'Ford', 'E-Series', 2020, 'White', 15, 'gasoline', 'automatic', '1FDUF3HT8BEA12345', '2024-12-31', '2024-12-31', 'active', 25000, '2024-01-15', '2024-07-15'),
('VEH002', 'DEF456', 'Chevrolet', 'Express', 2021, 'Blue', 12, 'gasoline', 'automatic', '1GBJ7C1A8BEA67890', '2025-06-30', '2025-06-30', 'active', 18000, '2024-02-20', '2024-08-20');

-- Vehicle assignments
INSERT INTO vehicle_assignments (vehicle_id, driver_id, assigned_date, assigned_by) VALUES
(1, 1, '2024-01-01', 1);

-- Routes
INSERT INTO routes (route_id, name, description, school_id, estimated_duration, distance, start_time, end_time, days_of_week, status) VALUES
('RT001', 'Morning Route 1', 'Primary morning route for elementary school', 1, 45, 12.5, '07:00:00', '08:30:00', 'monday,tuesday,wednesday,thursday,friday', 'active'),
('RT002', 'Afternoon Route 1', 'Primary afternoon route for elementary school', 1, 50, 12.5, '14:30:00', '16:00:00', 'monday,tuesday,wednesday,thursday,friday', 'active');

-- Route stops
INSERT INTO route_stops (route_id, stop_name, address, latitude, longitude, stop_order, estimated_arrival_time, is_pickup, is_dropoff) VALUES
(1, 'Central Park Stop', '100 Central Park Ave, City, State 12345', 40.7128, -74.0060, 1, '07:15:00', TRUE, FALSE),
(1, 'Sample Elementary School', '123 Education St, City, State 12345', 40.7505, -73.9934, 2, '08:00:00', FALSE, TRUE),
(2, 'Sample Elementary School', '123 Education St, City, State 12345', 40.7505, -73.9934, 1, '14:45:00', TRUE, FALSE),
(2, 'Central Park Stop', '100 Central Park Ave, City, State 12345', 40.7128, -74.0060, 2, '15:30:00', FALSE, TRUE);

-- Route assignments
INSERT INTO route_assignments (route_id, driver_id, vehicle_id, assigned_date, assigned_by) VALUES
(1, 1, 1, '2024-01-01', 1),
(2, 1, 1, '2024-01-01', 1);

-- Students
INSERT INTO students (student_id, first_name, last_name, date_of_birth, gender, school_id, grade, address, phone, email, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, medical_conditions, allergies, medications) VALUES
('STU001', 'Emma', 'Anderson', '2015-05-12', 'female', 1, '3rd Grade', '101 Student St, City, State 12345', '555-001-0001', 'emma.anderson@student.edu', 'Lisa Anderson', '555-001-0002', 'Mother', 'Asthma', 'Peanuts', 'Inhaler'),
('STU002', 'James', 'Taylor', '2014-08-23', 'male', 1, '4th Grade', '102 Student Ave, City, State 12345', '555-002-0001', 'james.taylor@student.edu', 'Robert Taylor', '555-002-0002', 'Father', NULL, 'Shellfish', NULL);

-- Student route assignments
INSERT INTO student_route_assignments (student_id, route_id, pickup_stop_id, dropoff_stop_id, assigned_date, assigned_by) VALUES
(1, 1, 1, 2, '2024-01-01', 1),
(1, 2, 2, 1, '2024-01-01', 1),
(2, 1, 1, 2, '2024-01-01', 1),
(2, 2, 2, 1, '2024-01-01', 1);

-- Trips
INSERT INTO trips (trip_id, route_id, driver_id, vehicle_id, scheduled_date, scheduled_start_time, scheduled_end_time, status, total_passengers, created_by) VALUES
('TRIP-20240115-0001', 1, 1, 1, '2024-01-15', '07:00:00', '08:30:00', 'completed', 2, 1),
('TRIP-20240115-0002', 2, 1, 1, '2024-01-15', '14:30:00', '16:00:00', 'completed', 2, 1),
('TRIP-20240116-0001', 1, 1, 1, '2024-01-16', '07:00:00', '08:30:00', 'scheduled', 2, 1);

-- Trip passengers
INSERT INTO trip_passengers (trip_id, student_id, pickup_stop_id, dropoff_stop_id, pickup_time, dropoff_time, status) VALUES
(1, 1, 1, 2, '2024-01-15 07:18:00', '2024-01-15 08:05:00', 'dropped_off'),
(1, 2, 1, 2, '2024-01-15 07:18:00', '2024-01-15 08:05:00', 'dropped_off'),
(2, 1, 2, 1, '2024-01-15 14:48:00', '2024-01-15 15:25:00', 'dropped_off'),
(2, 2, 2, 1, '2024-01-15 14:48:00', '2024-01-15 15:25:00', 'dropped_off');

-- Trip tracking data
INSERT INTO trip_tracking (trip_id, latitude, longitude, speed, heading, timestamp) VALUES
(1, 40.7128, -74.0060, 25.5, 90, '2024-01-15 07:00:00'),
(1, 40.7300, -73.9900, 28.8, 90, '2024-01-15 07:10:00'),
(1, 40.7505, -73.9934, 0.0, 0, '2024-01-15 08:00:00');

-- Maintenance records
INSERT INTO maintenance_records (vehicle_id, maintenance_type, description, cost, mileage_at_service, service_date, completed_date, vendor_name, vendor_phone, status, created_by) VALUES
(1, 'scheduled', 'Oil change and filter replacement', 85.50, 24000, '2024-01-15', '2024-01-15', 'City Auto Service', '555-111-9999', 'completed', 1),
(2, 'scheduled', 'Brake inspection and pad replacement', 320.00, 17000, '2024-02-20', '2024-02-20', 'Precision Brakes', '555-222-8888', 'completed', 1);

-- Alerts
INSERT INTO alerts (alert_type, severity, title, message, related_entity_type, related_entity_id, is_resolved, created_by) VALUES
('maintenance', 'medium', 'Vehicle Maintenance Due', 'Vehicle ABC123 requires scheduled maintenance in 5 days', 'vehicle', 1, FALSE, 1),
('safety', 'high', 'Driver License Expiring', 'Driver Mike Johnson license expires in 30 days', 'driver', 1, FALSE, 1);

-- Geofences
INSERT INTO geofences (name, description, geofence_type, latitude, longitude, radius, created_by) VALUES
('School Zone - Elementary', 'Speed limit zone around elementary school', 'school_zone', 40.7505, -73.9934, 200, 1),
('Central Park Pickup Area', 'Designated pickup area in Central Park', 'pickup_area', 40.7128, -74.0060, 50, 1);

-- Notification rules
INSERT INTO notification_rules (rule_name, alert_type, severity, notification_method, recipients, created_by) VALUES
('Maintenance Alerts', 'maintenance', 'high', 'email', '["admin@godrop.com", "manager@godrop.com"]', 1),
('Safety Alerts', 'safety', 'critical', 'sms', '["admin@godrop.com", "manager@godrop.com"]', 1);



