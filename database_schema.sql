-- =====================================================
-- School Fleet Management System Database Schema
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS godrop_db;
USE godrop_db;

-- =====================================================
-- USERS AND AUTHENTICATION
-- =====================================================

-- Users table for authentication
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('admin', 'manager', 'driver', 'parent', 'student') NOT NULL DEFAULT 'admin',
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- User sessions for token management
CREATE TABLE user_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    access_token VARCHAR(500) NOT NULL,
    refresh_token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_access_token (access_token),
    INDEX idx_refresh_token (refresh_token)
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token)
);

-- =====================================================
-- ORGANIZATION AND SCHOOLS
-- =====================================================

-- Schools table
CREATE TABLE schools (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    principal_name VARCHAR(255),
    school_type ENUM('elementary', 'middle', 'high', 'combined') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- STUDENTS MANAGEMENT
-- =====================================================

-- Students table
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    school_id INT NOT NULL,
    grade VARCHAR(20),
    address TEXT NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(100),
    medical_conditions TEXT,
    allergies TEXT,
    medications TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_student_id (student_id),
    INDEX idx_school_id (school_id),
    INDEX idx_is_active (is_active)
);

-- Student documents
CREATE TABLE student_documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    document_type ENUM('photo', 'medical_form', 'emergency_contact', 'permission_slip', 'other') NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    INDEX idx_student_id (student_id),
    INDEX idx_document_type (document_type)
);

-- =====================================================
-- DRIVERS MANAGEMENT
-- =====================================================

-- Drivers table
CREATE TABLE drivers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id VARCHAR(50) UNIQUE NOT NULL,
    user_id INT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    license_expiry DATE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    address TEXT NOT NULL,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    hire_date DATE NOT NULL,
    status ENUM('active', 'inactive', 'suspended', 'terminated') DEFAULT 'active',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_driver_id (driver_id),
    INDEX idx_license_number (license_number),
    INDEX idx_status (status)
);

-- Driver documents
CREATE TABLE driver_documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    document_type ENUM('license', 'medical_certificate', 'background_check', 'training_certificate', 'other') NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    expiry_date DATE,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_document_type (document_type),
    INDEX idx_expiry_date (expiry_date)
);

-- =====================================================
-- FLEET MANAGEMENT
-- =====================================================

-- Vehicles table
CREATE TABLE vehicles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id VARCHAR(50) UNIQUE NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(50),
    capacity INT NOT NULL,
    fuel_type ENUM('gasoline', 'diesel', 'electric', 'hybrid', 'other') NOT NULL,
    transmission ENUM('automatic', 'manual') NOT NULL,
    vin VARCHAR(17) UNIQUE,
    registration_expiry DATE,
    insurance_expiry DATE,
    status ENUM('active', 'maintenance', 'out_of_service', 'retired') DEFAULT 'active',
    current_mileage INT DEFAULT 0,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_license_plate (license_plate),
    INDEX idx_status (status)
);

-- Vehicle assignments
CREATE TABLE vehicle_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    unassigned_date DATE NULL,
    assigned_by INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (assigned_by) REFERENCES users(id),
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_assigned_date (assigned_date)
);

-- =====================================================
-- ROUTES MANAGEMENT
-- =====================================================

-- Routes table
CREATE TABLE routes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    route_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    school_id INT NOT NULL,
    estimated_duration INT, -- in minutes
    distance DECIMAL(8,2), -- in kilometers
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    days_of_week SET('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_route_id (route_id),
    INDEX idx_school_id (school_id),
    INDEX idx_status (status)
);

-- Route stops
CREATE TABLE route_stops (
    id INT PRIMARY KEY AUTO_INCREMENT,
    route_id INT NOT NULL,
    stop_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    stop_order INT NOT NULL,
    estimated_arrival_time TIME,
    is_pickup BOOLEAN DEFAULT TRUE,
    is_dropoff BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    INDEX idx_route_id (route_id),
    INDEX idx_stop_order (stop_order)
);

-- Route assignments
CREATE TABLE route_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    route_id INT NOT NULL,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    unassigned_date DATE NULL,
    assigned_by INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (assigned_by) REFERENCES users(id),
    INDEX idx_route_id (route_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_vehicle_id (vehicle_id)
);

-- Student route assignments
CREATE TABLE student_route_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    route_id INT NOT NULL,
    pickup_stop_id INT NOT NULL,
    dropoff_stop_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    unassigned_date DATE NULL,
    assigned_by INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (route_id) REFERENCES routes(id),
    FOREIGN KEY (pickup_stop_id) REFERENCES route_stops(id),
    FOREIGN KEY (dropoff_stop_id) REFERENCES route_stops(id),
    FOREIGN KEY (assigned_by) REFERENCES users(id),
    INDEX idx_student_id (student_id),
    INDEX idx_route_id (route_id)
);

-- =====================================================
-- TRIPS MANAGEMENT
-- =====================================================

-- Trips table
CREATE TABLE trips (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id VARCHAR(50) UNIQUE NOT NULL,
    route_id INT NOT NULL,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIMESTAMP NULL,
    actual_end_time TIMESTAMP NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled', 'delayed') DEFAULT 'scheduled',
    total_passengers INT DEFAULT 0,
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_trip_id (trip_id),
    INDEX idx_route_id (route_id),
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_status (status)
);

-- Trip passengers
CREATE TABLE trip_passengers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id INT NOT NULL,
    student_id INT NOT NULL,
    pickup_stop_id INT NOT NULL,
    dropoff_stop_id INT NOT NULL,
    pickup_time TIMESTAMP NULL,
    dropoff_time TIMESTAMP NULL,
    status ENUM('scheduled', 'picked_up', 'dropped_off', 'no_show', 'cancelled') DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (pickup_stop_id) REFERENCES route_stops(id),
    FOREIGN KEY (dropoff_stop_id) REFERENCES route_stops(id),
    INDEX idx_trip_id (trip_id),
    INDEX idx_student_id (student_id),
    INDEX idx_status (status)
);

-- Trip tracking data
CREATE TABLE trip_tracking (
    id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id INT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2),
    heading INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    INDEX idx_trip_id (trip_id),
    INDEX idx_timestamp (timestamp)
);

-- =====================================================
-- MAINTENANCE MANAGEMENT
-- =====================================================

-- Maintenance records
CREATE TABLE maintenance_records (
    id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    maintenance_type ENUM('scheduled', 'repair', 'inspection', 'emergency') NOT NULL,
    description TEXT NOT NULL,
    cost DECIMAL(10, 2),
    mileage_at_service INT,
    service_date DATE NOT NULL,
    completed_date DATE,
    vendor_name VARCHAR(255),
    vendor_phone VARCHAR(20),
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_vehicle_id (vehicle_id),
    INDEX idx_maintenance_type (maintenance_type),
    INDEX idx_service_date (service_date),
    INDEX idx_status (status)
);

-- =====================================================
-- ALERTS AND NOTIFICATIONS
-- =====================================================

-- Alerts table
CREATE TABLE alerts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    alert_type ENUM('safety', 'maintenance', 'schedule', 'weather', 'emergency', 'system') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type ENUM('trip', 'vehicle', 'driver', 'student', 'route', 'system') NULL,
    related_entity_id INT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INT NULL,
    resolved_at TIMESTAMP NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (resolved_by) REFERENCES users(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_is_resolved (is_resolved),
    INDEX idx_created_at (created_at)
);

-- Notification rules
CREATE TABLE notification_rules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    rule_name VARCHAR(255) NOT NULL,
    alert_type ENUM('safety', 'maintenance', 'schedule', 'weather', 'emergency', 'system') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    notification_method ENUM('email', 'sms', 'push', 'in_app') NOT NULL,
    recipients JSON NOT NULL, -- Array of user IDs or email addresses
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_is_active (is_active)
);

-- =====================================================
-- GEOFENCING
-- =====================================================

-- Geofences table
CREATE TABLE geofences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    geofence_type ENUM('school_zone', 'pickup_area', 'dropoff_area', 'restricted_area', 'speed_limit') NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    radius DECIMAL(8, 2) NOT NULL, -- in meters
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_geofence_type (geofence_type),
    INDEX idx_is_active (is_active)
);

-- Geofence violations
CREATE TABLE geofence_violations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    geofence_id INT NOT NULL,
    trip_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    violation_type ENUM('entry', 'exit', 'speed_limit') NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT NULL,
    acknowledged_at TIMESTAMP NULL,
    FOREIGN KEY (geofence_id) REFERENCES geofences(id),
    FOREIGN KEY (trip_id) REFERENCES trips(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (acknowledged_by) REFERENCES users(id),
    INDEX idx_geofence_id (geofence_id),
    INDEX idx_trip_id (trip_id),
    INDEX idx_violation_type (violation_type),
    INDEX idx_timestamp (timestamp)
);

-- =====================================================
-- REPORTS AND ANALYTICS
-- =====================================================

-- Report templates
CREATE TABLE report_templates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    report_type ENUM('trip_summary', 'driver_performance', 'vehicle_maintenance', 'student_attendance', 'safety_incidents', 'financial') NOT NULL,
    template_config JSON NOT NULL, -- Report configuration and filters
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_report_type (report_type),
    INDEX idx_is_active (is_active)
);

-- Scheduled reports
CREATE TABLE scheduled_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    template_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    schedule_type ENUM('daily', 'weekly', 'monthly', 'quarterly', 'yearly') NOT NULL,
    schedule_config JSON NOT NULL, -- Cron-like configuration
    recipients JSON NOT NULL, -- Array of email addresses
    is_active BOOLEAN DEFAULT TRUE,
    last_generated TIMESTAMP NULL,
    next_generation TIMESTAMP NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES report_templates(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_template_id (template_id),
    INDEX idx_is_active (is_active),
    INDEX idx_next_generation (next_generation)
);

-- =====================================================
-- SYSTEM SETTINGS
-- =====================================================

-- System settings
CREATE TABLE system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(255) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type ENUM('string', 'number', 'boolean', 'json') NOT NULL DEFAULT 'string',
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key),
    INDEX idx_is_public (is_public)
);

-- =====================================================
-- AUDIT LOGS
-- =====================================================

-- Audit logs for tracking changes
CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity_type (entity_type),
    INDEX idx_entity_id (entity_id),
    INDEX idx_created_at (created_at)
);

-- =====================================================
-- INITIAL DATA INSERTION
-- =====================================================

-- Insert default admin user
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active, email_verified)
VALUES ('admin@godrop.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Super', 'Admin', 'admin', TRUE, TRUE);

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, setting_type, description, is_public) VALUES
('system_name', 'GoDrop Fleet Management System', 'string', 'System display name', TRUE),
('max_trip_duration', '120', 'number', 'Maximum trip duration in minutes', FALSE),
('alert_retention_days', '90', 'number', 'Number of days to retain alerts', FALSE),
('maintenance_reminder_days', '7', 'number', 'Days before maintenance due to send reminder', FALSE),
('geofence_radius_default', '100', 'number', 'Default geofence radius in meters', FALSE),
('enable_sms_notifications', 'true', 'boolean', 'Enable SMS notifications', FALSE),
('enable_email_notifications', 'true', 'boolean', 'Enable email notifications', TRUE);

-- Insert sample school
INSERT INTO schools (name, address, phone, email, principal_name, school_type)
VALUES ('Sample Elementary School', '123 Education St, City, State 12345', '555-123-4567', 'info@sample.edu', 'Dr. Jane Smith', 'elementary');

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional composite indexes for better query performance
CREATE INDEX idx_trips_route_date ON trips(route_id, scheduled_date);
CREATE INDEX idx_trips_driver_date ON trips(driver_id, scheduled_date);
CREATE INDEX idx_trips_vehicle_date ON trips(vehicle_id, scheduled_date);
CREATE INDEX idx_trip_passengers_trip_status ON trip_passengers(trip_id, status);
CREATE INDEX idx_alerts_entity ON alerts(related_entity_type, related_entity_id);
CREATE INDEX idx_audit_logs_user_action ON audit_logs(user_id, action);
CREATE INDEX idx_maintenance_vehicle_date ON maintenance_records(vehicle_id, service_date);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Active trips view
CREATE VIEW active_trips AS
SELECT
    t.*,
    r.name as route_name,
    d.first_name as driver_first_name,
    d.last_name as driver_last_name,
    v.license_plate,
    v.make as vehicle_make,
    v.model as vehicle_model
FROM trips t
JOIN routes r ON t.route_id = r.id
JOIN drivers d ON t.driver_id = d.id
JOIN vehicles v ON t.vehicle_id = v.id
WHERE t.status IN ('scheduled', 'in_progress')
AND t.scheduled_date >= CURDATE();

-- Driver performance view
CREATE VIEW driver_performance AS
SELECT
    d.id,
    d.first_name,
    d.last_name,
    COUNT(t.id) as total_trips,
    COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_trips,
    COUNT(CASE WHEN t.status = 'cancelled' THEN 1 END) as cancelled_trips,
    AVG(TIMESTAMPDIFF(MINUTE, t.actual_start_time, t.actual_end_time)) as avg_trip_duration
FROM drivers d
LEFT JOIN trips t ON d.id = t.driver_id
    AND t.scheduled_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE d.is_active = TRUE
GROUP BY d.id, d.first_name, d.last_name;

-- Vehicle maintenance summary view
CREATE VIEW vehicle_maintenance_summary AS
SELECT
    v.id,
    v.license_plate,
    v.make,
    v.model,
    v.current_mileage,
    v.last_maintenance_date,
    v.next_maintenance_date,
    COUNT(m.id) as total_maintenance_records,
    SUM(m.cost) as total_maintenance_cost
FROM vehicles v
LEFT JOIN maintenance_records m ON v.id = m.vehicle_id
WHERE v.is_active = TRUE
GROUP BY v.id, v.license_plate, v.make, v.model, v.current_mileage, v.last_maintenance_date, v.next_maintenance_date;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Procedure to create a new trip
CREATE PROCEDURE CreateTrip(
    IN p_route_id INT,
    IN p_driver_id INT,
    IN p_vehicle_id INT,
    IN p_scheduled_date DATE,
    IN p_scheduled_start_time TIME,
    IN p_scheduled_end_time TIME,
    IN p_created_by INT
)
BEGIN
    DECLARE new_trip_id VARCHAR(50);

    -- Generate trip ID
    SET new_trip_id = CONCAT('TRIP-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD((SELECT COUNT(*) + 1 FROM trips WHERE DATE(created_at) = CURDATE()), 4, '0'));

    -- Insert trip
    INSERT INTO trips (trip_id, route_id, driver_id, vehicle_id, scheduled_date, scheduled_start_time, scheduled_end_time, created_by)
    VALUES (new_trip_id, p_route_id, p_driver_id, p_vehicle_id, p_scheduled_date, p_scheduled_start_time, p_scheduled_end_time, p_created_by);

    SELECT LAST_INSERT_ID() as trip_id;
END //

-- Procedure to assign students to a trip
CREATE PROCEDURE AssignStudentsToTrip(
    IN p_trip_id INT
)
BEGIN
    INSERT INTO trip_passengers (trip_id, student_id, pickup_stop_id, dropoff_stop_id)
    SELECT
        p_trip_id,
        sra.student_id,
        sra.pickup_stop_id,
        sra.dropoff_stop_id
    FROM student_route_assignments sra
    JOIN trips t ON sra.route_id = t.route_id
    WHERE t.id = p_trip_id
    AND sra.unassigned_date IS NULL
    AND sra.assigned_date <= t.scheduled_date;
END //

-- Procedure to generate maintenance alerts
CREATE PROCEDURE GenerateMaintenanceAlerts()
BEGIN
    INSERT INTO alerts (alert_type, severity, title, message, related_entity_type, related_entity_id, created_by)
    SELECT
        'maintenance',
        CASE
            WHEN DATEDIFF(v.next_maintenance_date, CURDATE()) <= 3 THEN 'critical'
            WHEN DATEDIFF(v.next_maintenance_date, CURDATE()) <= 7 THEN 'high'
            ELSE 'medium'
        END,
        CONCAT('Maintenance Due: ', v.license_plate),
        CONCAT('Vehicle ', v.license_plate, ' requires maintenance on ', DATE_FORMAT(v.next_maintenance_date, '%M %d, %Y')),
        'vehicle',
        v.id,
        1 -- Default admin user
    FROM vehicles v
    WHERE v.is_active = TRUE
    AND v.next_maintenance_date IS NOT NULL
    AND v.next_maintenance_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    AND v.next_maintenance_date >= CURDATE()
    AND NOT EXISTS (
        SELECT 1 FROM alerts a
        WHERE a.related_entity_type = 'vehicle'
        AND a.related_entity_id = v.id
        AND a.alert_type = 'maintenance'
        AND a.is_resolved = FALSE
    );
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger to update vehicle mileage after trip completion
CREATE TRIGGER update_vehicle_mileage
AFTER UPDATE ON trips
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE vehicles
        SET current_mileage = current_mileage + 50 -- Assuming average trip distance
        WHERE id = NEW.vehicle_id;
    END IF;
END //

-- Trigger to create audit log for user changes
CREATE TRIGGER audit_user_changes
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF OLD.email != NEW.email OR OLD.is_active != NEW.is_active OR OLD.role != NEW.role THEN
        INSERT INTO audit_logs (user_id, action, entity_type, entity_id, old_values, new_values)
        VALUES (
            NEW.id,
            'UPDATE',
            'user',
            NEW.id,
            JSON_OBJECT('email', OLD.email, 'is_active', OLD.is_active, 'role', OLD.role),
            JSON_OBJECT('email', NEW.email, 'is_active', NEW.is_active, 'role', NEW.role)
        );
    END IF;
END //

DELIMITER ;

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

/*
This database schema supports a comprehensive school fleet management system with the following features:

1. User Authentication & Authorization
   - Multi-role user system (admin, manager, driver, parent, student)
   - Session management with JWT tokens
   - Password reset functionality

2. Student Management
   - Complete student profiles with medical information
   - Document management
   - Emergency contact information

3. Driver Management
   - Driver profiles with licensing information
   - Document management (licenses, medical certificates, etc.)
   - Performance tracking

4. Fleet Management
   - Vehicle inventory with detailed specifications
   - Maintenance tracking
   - Vehicle assignments to drivers

5. Route Management
   - Route creation with stops
   - Route assignments to drivers and vehicles
   - Student route assignments

6. Trip Management
   - Trip scheduling and execution
   - Passenger tracking
   - Real-time location tracking

7. Maintenance Management
   - Scheduled and emergency maintenance
   - Cost tracking
   - Vendor management

8. Alerts & Notifications
   - Multi-level alert system
   - Configurable notification rules
   - Geofence violations

9. Reporting & Analytics
   - Customizable report templates
   - Scheduled report generation
   - Performance metrics

10. System Administration
    - Configurable system settings
    - Audit logging
    - Geofencing capabilities

The schema includes proper indexing for performance, views for common queries,
stored procedures for complex operations, and triggers for data integrity.
*/
