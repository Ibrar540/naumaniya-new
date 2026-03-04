/**
 * Test Dynamic Section Detection
 * Run this to test if user-created sections are detected correctly
 */

const axios = require('axios');

// Change this to your deployed Vercel URL or use localhost for local testing
const BASE_URL = 'http://localhost:3000'; // or 'https://your-app.vercel.app'

const testQueries = [
  {
    name: 'Test 1: Dynamic section "Ali" in masjid income',
    query: 'Give me total income from Ali',
    expected: 'Should detect "Ali" as section and return sum for Ali section only'
  },
  {
    name: 'Test 2: Dynamic section with year',
    query: 'Total income from Ali in 2025',
    expected: 'Should detect "Ali" section and filter by year 2025'
  },
  {
    name: 'Test 3: Dynamic section in madrasa',
    query: 'Show me madrasa income from Zakat',
    expected: 'Should detect "Zakat" section in madrasa income'
  },
  {
    name: 'Test 4: Dynamic section in expenditure',
    query: 'Total masjid expenditure from Electricity',
    expected: 'Should detect "Electricity" section in masjid expenditure'
  },
  {
    name: 'Test 5: No section specified',
    query: 'Total masjid income in 2025',
    expected: 'Should return total for all sections'
  },
  {
    name: 'Test 6: Multiple words section name',
    query: 'Give me income from Sadqa Jariya',
    expected: 'Should detect "Sadqa Jariya" as section name'
  },
  {
    name: 'Test 7: Urdu section name',
    query: 'مسجد کی زکوٰۃ آمدنی',
    expected: 'Should detect Urdu section name if exists'
  },
  {
    name: 'Test 8: Case insensitive',
    query: 'total income from DONATION',
    expected: 'Should detect "donation" regardless of case'
  }
];

async function runTests() {
  console.log('🧪 Starting Dynamic Section Detection Tests\n');
  console.log('=' .repeat(80));

  for (let i = 0; i < testQueries.length; i++) {
    const test = testQueries[i];
    console.log(`\n${test.name}`);
    console.log(`Query: "${test.query}"`);
    console.log(`Expected: ${test.expected}`);
    console.log('-'.repeat(80));

    try {
      const response = await axios.post(`${BASE_URL}/ai-query`, {
        message: test.query
      });

      console.log('✅ Response received:');
      console.log(`   Intent: ${response.data.intent}`);
      console.log(`   Module: ${response.data.module}`);
      console.log(`   Type: ${response.data.type}`);
      console.log(`   Section: ${response.data.section || 'ALL SECTIONS'}`);
      console.log(`   Year: ${response.data.year || 'N/A'}`);
      console.log(`   Result: ${JSON.stringify(response.data.result)}`);
      console.log(`   Message: ${response.data.message}`);

    } catch (error) {
      console.log('❌ Error:');
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Error: ${JSON.stringify(error.response.data)}`);
      } else {
        console.log(`   ${error.message}`);
      }
    }
  }

  console.log('\n' + '='.repeat(80));
  console.log('🏁 Tests completed\n');
}

// Run tests
runTests().catch(console.error);
