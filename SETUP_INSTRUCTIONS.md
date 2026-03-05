# Authentication System Setup Instructions

## ✅ What's Done

1. ✅ All authentication code created
2. ✅ Backend services, routes, and middleware
3. ✅ Flutter screens and services
4. ✅ Database schema ready
5. ✅ Code pushed to GitHub
6. ✅ Vercel will auto-deploy

## ⏳ What You Need to Do

### Step 1: Wait for Vercel Deployment (2-3 minutes)

Vercel is currently deploying your backend. However, it will FAIL because dependencies need to be installed.

**Why it fails:** The `bcrypt` and `jsonwebtoken` packages need to be compiled during deployment.

**Solution:** Vercel will automatically install them from `package.json` during deployment. The deployment should succeed automatically.

### Step 2: Check Vercel Deployment Status

1. Go to https://vercel.com/dashboard
2. Find your `naumaniya-new` project
3. Check the latest deployment
4. If it shows "Ready", proceed to Step 3
5. If it shows "Failed", check the logs:
   - Click on the failed deployment
   - Look for error messages
   - Most likely it will succeed on retry

### Step 3: Run Database Schema

You need to execute the SQL schema in your Neon database:

**Option A: Neon Web Console (Easiest)**
1. Go to https://console.neon.tech
2. Select your database
3. Click "SQL Editor"
4. Open `database/auth_schema.sql` from your project
5. Copy all contents
6. Paste into SQL Editor
7. Click "Run" or press Ctrl+Enter

**Option B: Using psql Command Line**
```bash
psql -h <your-neon-host> -U <username> -d <database> -f database/auth_schema.sql
```

**What this does:**
- Creates `users` table
- Creates `admin_requests` table
- Creates `auth_sessions` table
- Adds indexes for performance
- Creates first admin user (admin/admin123)

### Step 4: Set Environment Variable (Optional but Recommended)

For production security, set a custom JWT secret:

1. Go to Vercel Dashboard
2. Select your project
3. Go to Settings → Environment Variables
4. Add new variable:
   - Name: `JWT_SECRET`
   - Value: `your-super-secret-random-string-here`
5. Redeploy

**Generate a secure secret:**
```bash
# On Windows PowerShell:
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

### Step 5: Test the Authentication System

**Test Signup:**
```bash
curl -X POST https://naumaniya-new.vercel.app/auth/signup -H "Content-Type: application/json" -d "{\"name\":\"testuser\",\"password\":\"test123\"}"
```

**Test Login:**
```bash
curl -X POST https://naumaniya-new.vercel.app/auth/login -H "Content-Type: application/json" -d "{\"name\":\"admin\",\"password\":\"admin123\"}"
```

**Expected Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "admin",
    "role": "admin",
    "isActive": true
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Step 6: Update Flutter App to Use Authentication

The authentication system is ready, but you need to integrate it into your Flutter app:

**A. Update main.dart to check authentication:**

```dart
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize auth service
  final authService = AuthService();
  await authService.initialize();
  
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  
  const MyApp({required this.authService, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        Provider.value(value: authService),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Naumaniya',
            theme: ThemeData(primarySwatch: Colors.blue),
            // Show login if not authenticated
            home: authService.isAuthenticated 
              ? const SplashScreen() 
              : const LoginScreen(),
          );
        },
      ),
    );
  }
}
```

**B. Update AI Chat Service to include auth token:**

In `lib/services/ai_chat_service.dart`, add auth headers:

```dart
import 'auth_service.dart';

// In the sendQuery method:
Future<Map<String, dynamic>> sendQuery(String message) async {
  final authService = AuthService();
  
  final response = await http.post(
    Uri.parse('$baseUrl/ai-query'),
    headers: authService.getAuthHeaders(), // Add this line
    body: jsonEncode({'message': message}),
  );
  
  // ... rest of code
}
```

### Step 7: Change Default Admin Password

**IMPORTANT:** The default admin password is `admin123`. Change it immediately!

**Option 1: Via Flutter App (After integration)**
1. Login as admin
2. Go to settings/profile
3. Change password

**Option 2: Via Database**
Generate a new bcrypt hash and update:
```sql
UPDATE users 
SET password_hash = '$2b$10$<new_bcrypt_hash>' 
WHERE name = 'admin';
```

You can generate a bcrypt hash online at: https://bcrypt-generator.com/

## Troubleshooting

### Vercel Deployment Failed
- Check Vercel logs for specific error
- Ensure `package.json` includes bcrypt and jsonwebtoken
- Try manual redeploy from Vercel dashboard

### Database Schema Error
- Ensure you're connected to the correct database
- Check if tables already exist (drop them first if needed)
- Verify you have CREATE TABLE permissions

### Authentication Not Working
- Verify database schema is applied
- Check Vercel environment variables
- Test endpoints with curl first
- Check backend logs in Vercel

### Flutter Build Errors
- Run `flutter pub get` to install dependencies
- Ensure all imports are correct
- Check for syntax errors in new files

## Next Steps After Setup

1. ✅ Test login/signup in Flutter app
2. ✅ Create admin panel UI for managing users
3. ✅ Add fingerprint authentication (optional)
4. ✅ Implement password reset functionality
5. ✅ Add user profile management
6. ✅ Create admin request approval UI

## Documentation

- Full API documentation: `docs/AUTHENTICATION_SYSTEM.md`
- Implementation summary: `AUTH_SYSTEM_COMPLETE.md`
- Database schema: `database/auth_schema.sql`

## Support

If you encounter issues:
1. Check Vercel deployment logs
2. Verify database schema is applied
3. Test API endpoints with curl
4. Check Flutter console for errors
5. Review documentation files

---

**Current Status:** ✅ Code deployed, waiting for Vercel build and database setup
