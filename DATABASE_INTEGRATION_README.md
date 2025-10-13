# Database Integration Guide for GoDrop Fleet Management System

## Overview

This guide provides step-by-step instructions for setting up the database and integrating it with the GoDrop Fleet Management System frontend application.

## Files Included

1. **`database_schema.sql`** - Complete database schema with all tables, indexes, views, stored procedures, and triggers
2. **`sample_data.sql`** - Sample data to populate the database with test information
3. **`DATABASE_INTEGRATION_README.md`** - This integration guide

## Prerequisites

- MySQL 8.0 or higher
- Node.js backend server (Express.js recommended)
- Access to create databases and users

## Database Setup Instructions

### Step 1: Create Database and User

```sql
-- Connect to MySQL as root or privileged user
mysql -u root -p

-- Create database
CREATE DATABASE godrop_db;

-- Create application user (optional but recommended)
CREATE USER 'godrop_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON godrop_db.* TO 'godrop_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 2: Run Database Schema

```bash
# Run the complete schema
mysql -u godrop_user -p godrop_db < database_schema.sql
```

### Step 3: Populate with Sample Data

```bash
# Run the sample data
mysql -u godrop_user -p godrop_db < sample_data.sql
```

## Backend API Integration

### Step 1: Install Dependencies

```bash
npm install mysql2 express cors helmet bcryptjs jsonwebtoken dotenv
```

### Step 2: Create Database Configuration

Create `config/database.js`:

```javascript
const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'godrop_user',
  password: process.env.DB_PASSWORD || 'your_secure_password',
  database: process.env.DB_NAME || 'godrop_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  acquireTimeout: 60000,
  timeout: 60000,
  reconnect: true
};

const pool = mysql.createPool(dbConfig);

module.exports = pool;
```

### Step 3: Create Environment Variables

Create `.env` file:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=godrop_user
DB_PASSWORD=your_secure_password
DB_NAME=godrop_db

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
PORT=3001
NODE_ENV=development

# Email Configuration (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# SMS Configuration (for notifications)
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
```

### Step 4: Create Authentication Middleware

Create `middleware/auth.js`:

```javascript
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Verify user exists and is active
    const [users] = await pool.execute(
      'SELECT id, email, first_name, last_name, role, is_active FROM users WHERE id = ? AND is_active = TRUE',
      [decoded.userId]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }

    req.user = users[0];
    next();
  } catch (error) {
    return res.status(403).json({ success: false, message: 'Invalid token' });
  }
};

const authorizeRole = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    next();
  };
};

module.exports = { authenticateToken, authorizeRole };
```

### Step 5: Create Authentication Routes

Create `routes/auth.js`:

```javascript
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Get user from database
    const [users] = await pool.execute(
      'SELECT id, email, password_hash, first_name, last_name, role, is_active FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const user = users[0];

    if (!user.is_active) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Generate tokens
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
    );

    // Store refresh token
    await pool.execute(
      'INSERT INTO user_sessions (user_id, access_token, refresh_token, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY))',
      [user.id, accessToken, refreshToken]
    );

    // Update last login
    await pool.execute(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          role: user.role
        }
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Logout endpoint
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    // Remove session
    await pool.execute(
      'DELETE FROM user_sessions WHERE access_token = ?',
      [token]
    );

    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Refresh token endpoint
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({ success: false, message: 'Refresh token required' });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);

    // Check if refresh token exists in database
    const [sessions] = await pool.execute(
      'SELECT * FROM user_sessions WHERE refresh_token = ? AND expires_at > NOW()',
      [refreshToken]
    );

    if (sessions.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    // Generate new access token
    const [users] = await pool.execute(
      'SELECT id, email, role FROM users WHERE id = ? AND is_active = TRUE',
      [decoded.userId]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    const user = users[0];
    const newAccessToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    // Update access token in database
    await pool.execute(
      'UPDATE user_sessions SET access_token = ? WHERE refresh_token = ?',
      [newAccessToken, refreshToken]
    );

    res.json({
      success: true,
      data: { accessToken: newAccessToken }
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({ success: false, message: 'Invalid refresh token' });
  }
});

// Verify token endpoint
router.get('/verify', authenticateToken, (req, res) => {
  res.json({
    success: true,
    data: { user: req.user }
  });
});

module.exports = router;
```

### Step 6: Create Main Server File

Create `server.js`:

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const authRoutes = require('./routes/auth');

const app = express();

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: 'Server is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Frontend Integration

### Step 1: Update API Configuration

Update `src/api/config/constants.js`:

```javascript
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001/api';
```

### Step 2: Update Environment Variables

Create `.env` file in frontend root:

```env
VITE_API_BASE_URL=http://localhost:3001/api
```

### Step 3: Update Authentication Context

The existing `AuthContext.jsx` should work with the new backend. Ensure the login function calls the correct API endpoint:

```javascript
// In AuthContext.jsx, update the login function
const login = async (credentials) => {
  try {
    const response = await authAPI.login(credentials);

    if (response.success) {
      // Store tokens
      localStorage.setItem('authToken', response.data.accessToken);
      localStorage.setItem('refreshToken', response.data.refreshToken);

      // Update user state
      setUser(response.data.user);
      setIsAuthenticated(true);

      return { success: true };
    } else {
      return { success: false, message: response.message };
    }
  } catch (error) {
    console.error('Login error:', error);
    return { success: false, message: 'Login failed' };
  }
};
```

## Testing the Integration

### Step 1: Start the Backend Server

```bash
cd backend
npm start
```

### Step 2: Start the Frontend

```bash
cd frontend
npm run dev
```

### Step 3: Test Login

Use the default admin credentials:
- Email: `admin@godrop.com`
- Password: `password` (or any password for demo)

## Database Queries for Common Operations

### Get Dashboard Metrics

```sql
-- Get total counts for dashboard
SELECT
  (SELECT COUNT(*) FROM students WHERE is_active = TRUE) as total_students,
  (SELECT COUNT(*) FROM drivers WHERE is_active = TRUE) as total_drivers,
  (SELECT COUNT(*) FROM vehicles WHERE is_active = TRUE) as total_vehicles,
  (SELECT COUNT(*) FROM trips WHERE scheduled_date = CURDATE()) as today_trips,
  (SELECT COUNT(*) FROM alerts WHERE is_resolved = FALSE) as active_alerts;
```

### Get Active Trips

```sql
-- Get all active trips with details
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
AND t.scheduled_date >= CURDATE()
ORDER BY t.scheduled_date, t.scheduled_start_time;
```

### Get Student Attendance

```sql
-- Get student attendance for a specific date
SELECT
  s.student_id,
  s.first_name,
  s.last_name,
  tp.pickup_time,
  tp.dropoff_time,
  tp.status,
  t.trip_id
FROM students s
JOIN trip_passengers tp ON s.id = tp.student_id
JOIN trips t ON tp.trip_id = t.id
WHERE DATE(t.scheduled_date) = '2024-01-15'
ORDER BY s.first_name, s.last_name;
```

## Security Considerations

1. **Password Hashing**: All passwords are hashed using bcrypt
2. **JWT Tokens**: Access and refresh tokens for secure authentication
3. **SQL Injection Prevention**: Use parameterized queries
4. **CORS Configuration**: Configure CORS for your specific domains
5. **Environment Variables**: Store sensitive data in environment variables
6. **Input Validation**: Validate all user inputs
7. **Rate Limiting**: Implement rate limiting for API endpoints

## Performance Optimization

1. **Database Indexes**: All necessary indexes are included in the schema
2. **Connection Pooling**: Use connection pooling for database connections
3. **Query Optimization**: Use the provided views for complex queries
4. **Caching**: Consider implementing Redis for session storage

## Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure MySQL is running and accessible
2. **Authentication Failed**: Check database credentials in .env file
3. **CORS Errors**: Verify CORS configuration matches your frontend URL
4. **JWT Errors**: Ensure JWT_SECRET is set in environment variables

### Debug Commands

```bash
# Check MySQL status
sudo systemctl status mysql

# Check database connection
mysql -u godrop_user -p godrop_db -e "SELECT 1;"

# Check server logs
tail -f /var/log/mysql/error.log
```

## Next Steps

1. Implement remaining API endpoints for all modules
2. Add real-time tracking with WebSocket connections
3. Implement email and SMS notifications
4. Add file upload functionality for documents
5. Implement reporting and analytics features
6. Add audit logging for compliance
7. Set up automated backups
8. Implement monitoring and alerting

## Support

For additional support or questions about the database integration, please refer to the project documentation or contact the development team.
