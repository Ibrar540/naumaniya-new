# AI Assistant Enhancements - Implementation Plan

## Requirements
1. ✅ Dynamic online suggestions (fetch from backend based on user input)
2. ✅ More intelligent AI (no default month/year when not specified)
3. ✅ Suggestions only while typing (hide after sending message)
4. ✅ Download/Print functionality for AI responses
5. ✅ Fix month detection bug

## Changes Required

### 1. Backend Changes (aiEngine.js)
**File**: `backend/utils/aiEngine.js`

**Changes**:
- ✅ Remove default year (return null instead of current year)
- ✅ Remove default month (return null instead of current month)
- This ensures queries like "summary of income of masjid 2026" don't add March

**Status**: COMPLETE

### 2. Backend - Add Suggestions Endpoint
**File**: `backend/index.js`

**New Endpoint**: `POST /ai-suggestions`
- Accepts partial user input
- Returns relevant suggestions based on:
  - Recent queries
  - Available sections
  - Common query patterns
- Returns 5-10 dynamic suggestions

### 3. Flutter - Update ChatMessage Model
**File**: `lib/models/chat_message.dart`

**Add**:
- `rawData` field to store backend response data
- `canExport` boolean flag
- Methods for export functionality

### 4. Flutter - Update AI Chat Service
**File**: `lib/services/ai_chat_service.dart`

**Add**:
- `getSuggestions(String partialInput)` method
- Calls backend `/ai-suggestions` endpoint
- Returns dynamic suggestions based on input
- Remove fixed suggestions from responses

### 5. Flutter - Update AI Chat Screen
**File**: `lib/screens/ai_chat_screen.dart`

**Add**:
- Real-time suggestion fetching as user types
- Debounced API calls (wait 300ms after typing stops)
- Show suggestions only in input area (not with responses)
- Download button for each AI response
- Print button for each AI response
- Export to PDF/Excel functionality

### 6. Add Export Utilities
**New File**: `lib/utils/ai_export_utils.dart`

**Functions**:
- `exportToPDF(ChatMessage message)` - Export AI response to PDF
- `exportToExcel(ChatMessage message)` - Export tabular data to Excel
- `printResponse(ChatMessage message)` - Print AI response

## Implementation Priority

### Phase 1: Backend Intelligence (COMPLETE)
- ✅ Fix month/year detection
- ⏳ Add suggestions endpoint

### Phase 2: Dynamic Suggestions
- Update chat service
- Update chat screen
- Add debounced input handling

### Phase 3: Export Functionality
- Add export utilities
- Add download/print buttons
- Implement PDF/Excel export

## Technical Details

### Dynamic Suggestions Flow
```
User types "total income" 
  ↓
Debounce 300ms
  ↓
Call /ai-suggestions with "total income"
  ↓
Backend returns:
  - "Total income of masjid in 2025"
  - "Total income of madrasa in 2024"
  - "Total income from Zakat"
  ↓
Display suggestions below input
  ↓
User selects or continues typing
```

### Export Flow
```
AI returns financial data
  ↓
Display with Download/Print buttons
  ↓
User clicks Download
  ↓
Show format options (PDF/Excel)
  ↓
Generate file
  ↓
Save to downloads folder
```

## UI Changes

### Before
```
[Input Box]
[Fixed Suggestions: "Total income...", "Madrasa..."]
[Chat Messages with suggestions in responses]
```

### After
```
[Input Box with dynamic suggestions while typing]
[Chat Messages]
  - AI Response
    [Download] [Print] buttons
  - User Message
  - AI Response
    [Download] [Print] buttons
```

## Dependencies Needed

```yaml
# pubspec.yaml
dependencies:
  pdf: ^3.10.0  # For PDF generation
  excel: ^2.1.0  # For Excel export
  path_provider: ^2.1.0  # For file paths
  printing: ^5.11.0  # For printing
```

## Next Steps

1. ✅ Fix backend month/year detection
2. Add backend suggestions endpoint
3. Update Flutter dependencies
4. Implement dynamic suggestions
5. Add export functionality
6. Test all features
