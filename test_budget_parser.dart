// Test file for Budget Search Parser
// Run this file to test the parser functionality

import 'lib/services/budget_search_parser.dart';

void main() {
  print('=== BUDGET SEARCH PARSER TESTS ===\n');
  
  // Test 1: Exact Amount
  print('TEST 1: Exact Amount');
  var result = BudgetSearchParser.parse('5000 rs', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 2: Amount Range
  print('TEST 2: Amount Range');
  result = BudgetSearchParser.parse('2000 to 5000', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 3: Greater Than
  print('TEST 3: Greater Than');
  result = BudgetSearchParser.parse('greater than 5000', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 4: Description
  print('TEST 4: Description');
  result = BudgetSearchParser.parse('electricity bill', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 5: Year
  print('TEST 5: Year');
  result = BudgetSearchParser.parse('2024', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 6: Month
  print('TEST 6: Month');
  result = BudgetSearchParser.parse('Jan 2024', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  // Test 7: Combined
  print('TEST 7: Combined');
  result = BudgetSearchParser.parse('salary 50000', false);
  print(BudgetSearchParser.toPrettyJson(result));
  print('\n---\n');
  
  print('=== ALL TESTS COMPLETED ===');
}
