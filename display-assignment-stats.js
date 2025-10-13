// Assignment Stats Display
// This file demonstrates how to display assignment statistics

console.log('📊 Assignment Stats Display\n');

// Mock assignment stats data (this would come from the API)
const assignmentStats = {
  "total_assignments": 9,
  "active_assignments": 0,
  "pending_assignments": 9,
  "completed_assignments": 0,
  "current_active_assignments": 0,
  "recent_assignments": 9,
  "assignments_by_status": [
    {
      "status": "pending",
      "count": 9
    }
  ]
};

// Function to display assignment stats
function displayAssignmentStats(stats) {
  console.log('=' .repeat(50));
  console.log('📊 ASSIGNMENT STATISTICS');
  console.log('=' .repeat(50));

  // Main statistics
  console.log(`📈 Total Assignments: ${stats.total_assignments}`);
  console.log(`🟢 Active Assignments: ${stats.active_assignments}`);
  console.log(`🟡 Pending Assignments: ${stats.pending_assignments}`);
  console.log(`✅ Completed Assignments: ${stats.completed_assignments}`);
  console.log(`🔄 Current Active: ${stats.current_active_assignments}`);
  console.log(`📅 Recent Assignments: ${stats.recent_assignments}`);

  console.log('\n📊 Assignments by Status:');
  if (stats.assignments_by_status && Array.isArray(stats.assignments_by_status)) {
    stats.assignments_by_status.forEach((item, index) => {
      const statusIcon = getStatusIcon(item.status);
      console.log(`  ${index + 1}. ${statusIcon} ${item.status.toUpperCase()}: ${item.count}`);
    });
  }

  console.log('\n' + '=' .repeat(50));
}

// Function to get status icon
function getStatusIcon(status) {
  const icons = {
    'pending': '🟡',
    'active': '🟢',
    'completed': '✅',
    'cancelled': '❌',
    'in_progress': '🔄',
    'scheduled': '📅'
  };
  return icons[status.toLowerCase()] || '📊';
}

// Function to display stats in a table format
function displayStatsTable(stats) {
  console.log('\n📊 Assignment Stats Table:');
  console.log('┌─────────────────────────┬─────────┐');
  console.log('│ Metric                  │ Count   │');
  console.log('├─────────────────────────┼─────────┤');
  console.log(`│ Total Assignments       │ ${stats.total_assignments.toString().padStart(7)} │`);
  console.log(`│ Active Assignments      │ ${stats.active_assignments.toString().padStart(7)} │`);
  console.log(`│ Pending Assignments     │ ${stats.pending_assignments.toString().padStart(7)} │`);
  console.log(`│ Completed Assignments   │ ${stats.completed_assignments.toString().padStart(7)} │`);
  console.log(`│ Current Active            │ ${stats.current_active_assignments.toString().padStart(7)} │`);
  console.log(`│ Recent Assignments      │ ${stats.recent_assignments.toString().padStart(7)} │`);
  console.log('└─────────────────────────┴─────────┘');
}

// Function to display status breakdown
function displayStatusBreakdown(stats) {
  console.log('\n📊 Status Breakdown:');
  if (stats.assignments_by_status && Array.isArray(stats.assignments_by_status)) {
    stats.assignments_by_status.forEach((item, index) => {
      const percentage = ((item.count / stats.total_assignments) * 100).toFixed(1);
      const bar = '█'.repeat(Math.floor(percentage / 5));
      console.log(`${getStatusIcon(item.status)} ${item.status.toUpperCase().padEnd(12)} │${bar.padEnd(20)}│ ${item.count} (${percentage}%)`);
    });
  }
}

// Function to display summary
function displaySummary(stats) {
  console.log('\n📋 Summary:');
  const total = stats.total_assignments;
  const active = stats.active_assignments;
  const pending = stats.pending_assignments;
  const completed = stats.completed_assignments;

  console.log(`• You have ${total} total assignments`);
  console.log(`• ${active} are currently active`);
  console.log(`• ${pending} are pending approval`);
  console.log(`• ${completed} have been completed`);

  if (pending > 0) {
    console.log(`⚠️  You have ${pending} pending assignments that need attention`);
  }

  if (active === 0 && pending > 0) {
    console.log('💡 Consider activating some pending assignments');
  }
}

// Display all formats
console.log('🚀 Displaying Assignment Statistics\n');

// Basic display
displayAssignmentStats(assignmentStats);

// Table format
displayStatsTable(assignmentStats);

// Status breakdown
displayStatusBreakdown(assignmentStats);

// Summary
displaySummary(assignmentStats);

console.log('\n🎉 Assignment stats display completed!');
