/**
 * Test Script for AI Assistant
 * Tests various natural language queries
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/ai-query';

// Test queries in English and Urdu
const testQueries = [
  // Total queries
  'Total income of masjid in 2025',
  'Total zakat income in 2025',
  'Total masjid expenditure last year',
  'Electricity expense March 2024',
  
  // Net balance queries
  'Net balance of masjid in 2025',
  'Balance of madrasa this year',
  
  // Comparison queries
  'Compare income of 2024 and 2025',
  'Compare masjid expenditure 2024 vs 2025',
  
  // Summary queries
  'Financial summary of madrasa 2025',
  'Summary of masjid last year',
  
  // Breakdown queries
  'Section wise breakdown of masjid income 2025',
  'Expenditure breakdown madrasa 2024',
  
  // Urdu queries
  'مسجد کی کل آمدنی 2025',
  'مدرسہ کا خرچ 2024',
  'زکوٰۃ آمدنی 2025',
  'مسجد کا خلاصہ 2025'
];

async function testQuery(message) {
  try {
    console.log('\n' + '='.repeat(60));
    console.log('📝 Query:', message);
    console.log('='.repeat(60));
    
    const response = await axios.post(API_URL, { message });
    
    console.log('✅ Success:', response.data.success);
    console.log('🎯 Intent:', response.data.intent);
    console.log('📊 Result:', JSON.stringify(response.data.result, null, 2));
    console.log('💬 Message:', response.data.message);
    
    if (response.data.urduMessage) {
      console.log('🇵🇰 Urdu:', response.data.urduMessage);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

async function runTests() {
  console.log('🧪 Starting AI Assistant Tests...\n');
  
  // Test health endpoint first
  try {
    const health = await axios.get('http://localhost:3000/health');
    console.log('✅ Server is healthy:', health.data);
  } catch (error) {
    console.error('❌ Server is not running. Please start the server first.');
    process.exit(1);
  }
  
  // Run all test queries
  for (const query of testQueries) {
    await testQuery(query);
    await new Promise(resolve => setTimeout(resolve, 500)); // Small delay between requests
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('✅ All tests completed!');
  console.log('='.repeat(60));
}

// Run tests
runTests().catch(console.error);
