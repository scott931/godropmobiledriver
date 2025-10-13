// Assignment Stats Page Diagnosis
console.log('🔍 Diagnosing Assignment Stats Page Issues...\n');

// Check if files exist
const fs = require('fs');
const path = require('path');

const filesToCheck = [
  'src/App.jsx',
  'src/pages/admin/MinimalTestPage.jsx',
  'src/pages/admin/AssignmentStatsPageSimple.jsx',
  'src/pages/admin/AssignmentStatsPage.jsx',
  'src/components/AdminLayout.jsx'
];

console.log('📁 Checking Required Files:');
filesToCheck.forEach(file => {
  const exists = fs.existsSync(file);
  console.log(`  ${exists ? '✅' : '❌'} ${file}`);
});

// Check App.jsx content
console.log('\n🔧 Checking App.jsx Configuration:');
try {
  const appContent = fs.readFileSync('src/App.jsx', 'utf8');

  const hasImport = appContent.includes("import MinimalTestPage from './pages/admin/MinimalTestPage'");
  const hasRoute = appContent.includes('<Route path="assignment-stats" element={<MinimalTestPage />} />');

  console.log(`  ${hasImport ? '✅' : '❌'} Import statement exists`);
  console.log(`  ${hasRoute ? '✅' : '❌'} Route configuration exists`);
} catch (error) {
  console.log('  ❌ Error reading App.jsx:', error.message);
}

// Check AdminLayout.jsx content
console.log('\n🔧 Checking AdminLayout.jsx Configuration:');
try {
  const layoutContent = fs.readFileSync('src/components/AdminLayout.jsx', 'utf8');

  const hasNavItem = layoutContent.includes("Assignment Stats");
  const hasPath = layoutContent.includes("/admin/assignment-stats");

  console.log(`  ${hasNavItem ? '✅' : '❌'} Navigation item exists`);
  console.log(`  ${hasPath ? '✅' : '❌'} Path configuration exists`);
} catch (error) {
  console.log('  ❌ Error reading AdminLayout.jsx:', error.message);
}

console.log('\n🚀 Troubleshooting Steps:');
console.log('1. Make sure development server is running: npm run dev');
console.log('2. Navigate to: http://localhost:5173/admin/assignment-stats');
console.log('3. Check browser console for errors');
console.log('4. Verify you are logged in');
console.log('5. Try clearing browser cache');

console.log('\n📱 Expected URLs:');
console.log('• Main app: http://localhost:5173/');
console.log('• Login: http://localhost:5173/login');
console.log('• Dashboard: http://localhost:5173/admin/dashboard');
console.log('• Assignment Stats: http://localhost:5173/admin/assignment-stats');

console.log('\n🔍 Common Issues:');
console.log('• Development server not running');
console.log('• Not logged in (redirected to login)');
console.log('• Browser cache issues');
console.log('• JavaScript errors in console');
console.log('• Import/export issues');

console.log('\n✅ If all files exist and are configured correctly,');
console.log('the page should load at: http://localhost:5173/admin/assignment-stats');
