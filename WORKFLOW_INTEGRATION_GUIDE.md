# Workflow Management System Integration Guide

## Overview

The new Workflow Management System provides a streamlined 4-stage process for setting up route tracking:

1. **Stage 1: Fleet Assignment** - Assign drivers to vehicles
2. **Stage 2: Route Assignment** - Assign vehicles and drivers to routes
3. **Stage 3: Student Assignment** - Assign students to routes with pickup/dropoff stops
4. **Stage 4: Trip Tracking** - Start trip tracking and monitoring

## Components Created

### 1. Workflow Validation (`src/lib/workflowValidation.js`)
- **Purpose**: Validates prerequisites for each workflow stage
- **Key Functions**:
  - `validateFleetAssignment()` - Checks driver-vehicle assignment validity
  - `validateRouteAssignment()` - Validates route assignments with prerequisites
  - `validateStudentAssignment()` - Ensures students can be assigned to routes
  - `validateTripTracking()` - Validates all prerequisites for trip start
  - `validateCompleteWorkflow()` - Validates entire workflow sequence
  - `getWorkflowStatus()` - Gets current status for a route

### 2. Workflow API Service (`src/api/services/workflowAPI.js`)
- **Purpose**: API layer for workflow operations
- **Key Features**:
  - Validation endpoints for each stage
  - Bulk operations for efficiency
  - Workflow execution and analytics
  - Status tracking across all routes

### 3. Guided Workflow Interface (`src/components/WorkflowGuide.jsx`)
- **Purpose**: Step-by-step workflow completion
- **Features**:
  - Interactive stage-by-stage guidance
  - Real-time validation feedback
  - Progress tracking
  - Data collection forms for each stage

### 4. Workflow Status Tracker (`src/components/WorkflowStatusTracker.jsx`)
- **Purpose**: Monitor workflow progress across all routes
- **Features**:
  - Overview dashboard with analytics
  - Status filtering and search
  - Bulk status management
  - Export capabilities

### 5. Bulk Operations (`src/components/BulkOperations.jsx`)
- **Purpose**: Efficient bulk assignment operations
- **Features**:
  - Bulk driver-to-vehicle assignments
  - Bulk route assignments
  - Bulk student-to-route assignments
  - Template downloads and CSV import/export

### 6. Main Workflow Management Page (`src/pages/admin/WorkflowManagementPage.jsx`)
- **Purpose**: Central hub for all workflow operations
- **Features**:
  - Integrated dashboard
  - Tabbed interface for different operations
  - Quick actions and recent activity
  - Settings management

## Integration Steps

### 1. Add to Navigation
Add the Workflow Management page to your admin navigation:

```jsx
// In your navigation component
{
  path: '/admin/workflow',
  name: 'Workflow Management',
  icon: Workflow,
  component: WorkflowManagementPage
}
```

### 2. Import Components
```jsx
import WorkflowManagementPage from './pages/admin/WorkflowManagementPage';
import WorkflowGuide from './components/WorkflowGuide';
import WorkflowStatusTracker from './components/WorkflowStatusTracker';
import BulkOperations from './components/BulkOperations';
```

### 3. Use Individual Components
You can also use individual components in other parts of your application:

```jsx
// For guided workflow
<WorkflowGuide
  routeId={routeId}
  onComplete={handleComplete}
  onCancel={handleCancel}
/>

// For status tracking
<WorkflowStatusTracker
  onRouteSelect={handleRouteSelect}
  onStartWorkflow={handleStartWorkflow}
/>

// For bulk operations
<BulkOperations onComplete={handleComplete} />
```

## API Endpoints

The system expects these backend endpoints:

```
GET  /api/v1/workflow/status/:routeId
GET  /api/v1/workflow/status/all
GET  /api/v1/workflow/analytics
POST /api/v1/workflow/validate/fleet
POST /api/v1/workflow/validate/route
POST /api/v1/workflow/validate/student
POST /api/v1/workflow/validate/trip
POST /api/v1/workflow/bulk/drivers
POST /api/v1/workflow/bulk/routes
POST /api/v1/workflow/bulk/students
POST /api/v1/workflow/execute
```

## Workflow States

- `not_started` - Stage not yet begun
- `in_progress` - Stage currently being worked on
- `completed` - Stage successfully completed
- `blocked` - Stage blocked due to validation errors
- `error` - Stage failed due to system error

## Usage Examples

### Starting a New Workflow
```jsx
const handleStartWorkflow = (route) => {
  setSelectedRoute(route);
  setShowWorkflowGuide(true);
};
```

### Checking Workflow Status
```jsx
const checkStatus = async (routeId) => {
  const result = await workflowAPI.getWorkflowStatus(routeId);
  if (result.success) {
    console.log('Workflow status:', result.data);
  }
};
```

### Bulk Assignment
```jsx
const assignments = [
  { driverId: 1, vehicleId: 1, notes: 'Primary assignment' },
  { driverId: 2, vehicleId: 2, notes: 'Backup assignment' }
];

const result = await workflowAPI.bulkAssignDriversToVehicles(assignments);
```

## Benefits

1. **Streamlined Process**: Clear 4-stage workflow eliminates confusion
2. **Validation**: Automatic prerequisite checking prevents errors
3. **Bulk Operations**: Efficient mass assignments save time
4. **Status Tracking**: Real-time visibility into workflow progress
5. **Guided Interface**: Step-by-step guidance reduces training needs
6. **Analytics**: Comprehensive reporting on workflow completion

## Next Steps

1. **Backend Integration**: Implement the required API endpoints
2. **Database Updates**: Ensure your database schema supports the workflow relationships
3. **Testing**: Test the workflow with sample data
4. **Training**: Train users on the new workflow process
5. **Monitoring**: Set up monitoring for workflow completion rates

The system is designed to be flexible and can be customized based on your specific requirements. All components are modular and can be used independently or together as needed.
