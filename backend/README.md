# AI Assistant Backend - Naumaniya Financial Management

Complete Node.js backend for natural language financial queries using rule-based NLP.

## Features

✅ Rule-based NLP (no paid AI APIs)
✅ English & Urdu support
✅ Parameterized SQL queries (SQL injection safe)
✅ Module detection (Masjid/Madrasa)
✅ Type detection (Income/Expenditure)
✅ Section detection (dynamic from database)
✅ Date detection (year, month, relative dates)
✅ Intent detection (total, net balance, compare, summary, breakdown)
✅ Production-ready architecture

## Installation

```bash
cd backend
npm install
```

## Configuration

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Update `.env` with your Neon PostgreSQL credentials:
```env
DATABASE_URL=postgresql://username:password@host/database?sslmode=require
PORT=3000
NODE_ENV=production
```

## Database Setup

Ensure your Neon database has these tables:
- `masjid_income`
- `masjid_expenditure`
- `madrasa_income`
- `madrasa_expenditure`

Each table should have:
```sql
id SERIAL PRIMARY KEY
section_name TEXT
amount NUMERIC
date DATE
description TEXT
```

## Running the Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## API Endpoints

### 1. AI Query (Main Endpoint)
```http
POST /ai-query
Content-Type: application/json

{
  "message": "Total income of masjid in 2025"
}
```

Response:
```json
{
  "success": true,
  "intent": "total",
  "module": "masjid",
  "type": "income",
  "year": 2025,
  "result": 450000,
  "message": "Total Income of Masjid in 2025 is 450,000 PKR.",
  "urduMessage": "مسجد کی کل آمدنی: 450,000 PKR"
}
```

### 2. Get Sections
```http
GET /sections?module=masjid&type=income
```

### 3. Get Years
```http
GET /years?module=masjid&type=income
```

### 4. Health Check
```http
GET /health
```

### 5. Test Database
```http
GET /test-db
```

## Supported Queries

### English Examples:
- "Total income of masjid in 2025"
- "Total zakat income in 2025"
- "Total masjid expenditure last year"
- "Electricity expense March 2024"
- "Net balance of masjid in 2025"
- "Compare income of 2024 and 2025"
- "Financial summary of madrasa 2025"
- "Section wise breakdown of masjid income"

### Urdu Examples:
- "مسجد کی کل آمدنی 2025"
- "مدرسہ کا خرچ 2024"
- "زکوٰۃ آمدنی 2025"
- "مسجد کا خلاصہ 2025"

## Testing

Run test queries:
```bash
npm test
```

Or manually test with curl:
```bash
curl -X POST http://localhost:3000/ai-query \
  -H "Content-Type: application/json" \
  -d '{"message": "Total income of masjid in 2025"}'
```

## Project Structure

```
backend/
├── config/
│   └── db.js              # Database connection
├── utils/
│   ├── aiEngine.js        # NLP intent detection
│   ├── queryBuilder.js    # SQL query builder
│   └── responseFormatter.js # Response formatting
├── test/
│   └── testQueries.js     # Test script
├── server.js              # Main Express server
├── package.json
├── .env.example
└── README.md
```

## Intent Types

1. **total** - Sum of amounts
2. **net_balance** - Income - Expenditure
3. **compare** - Year-wise comparison
4. **summary** - Complete financial overview
5. **breakdown** - Section-wise breakdown

## Security Features

- Helmet.js for security headers
- CORS configuration
- Parameterized queries (SQL injection prevention)
- Input validation
- Error handling
- No credentials in frontend

## Integration with Flutter App

Update your Flutter app's AI service to call this backend:

```dart
Future<Map<String, dynamic>> queryAI(String message) async {
  final response = await http.post(
    Uri.parse('http://your-server:3000/ai-query'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'message': message}),
  );
  return json.decode(response.body);
}
```

## Deployment

### Option 1: Deploy to Heroku
```bash
heroku create naumaniya-ai-backend
git push heroku main
```

### Option 2: Deploy to Railway
```bash
railway init
railway up
```

### Option 3: Deploy to Render
Connect your GitHub repo to Render and deploy.

## Environment Variables

- `DATABASE_URL` - Neon PostgreSQL connection string
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `ALLOWED_ORIGINS` - CORS allowed origins

## Troubleshooting

### Database connection fails
- Check DATABASE_URL in .env
- Ensure Neon database is accessible
- Verify SSL settings

### Queries not working
- Check table names match (masjid_income, etc.)
- Verify column names (section_name, amount, date)
- Check data types

### Section not detected
- Ensure section names exist in database
- Check spelling and case sensitivity

## License

MIT

## Support

For issues or questions, contact the development team.
