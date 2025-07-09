# Firebase Setup Guide for Naumaniya School Management

## Prerequisites
- Google account
- Firebase project (free tier is sufficient)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `naumaniya-school-management`
4. Enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Add Web App

1. In your Firebase project dashboard, click the web icon (</>)
2. Enter app nickname: `naumaniya-web`
3. Check "Also set up Firebase Hosting" (optional)
4. Click "Register app"
5. **Copy the configuration object** - you'll need this for the next step

## Step 3: Enable Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" authentication
3. Click "Save"

## Step 4: Set up Firestore Database

1. Go to "Firestore Database" in Firebase Console
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users (e.g., us-central1)
5. Click "Done"

## Step 5: Update App Configuration

### Replace the placeholder values in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY', // From Firebase config
  appId: 'YOUR_ACTUAL_APP_ID', // From Firebase config
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID', // From Firebase config
  projectId: 'YOUR_ACTUAL_PROJECT_ID', // From Firebase config
  authDomain: 'YOUR_ACTUAL_AUTH_DOMAIN', // From Firebase config
  storageBucket: 'YOUR_ACTUAL_STORAGE_BUCKET', // From Firebase config
);
```

### Example with real values:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyB1234567890abcdefghijklmnopqrstuvwxyz',
  appId: '1:123456789012:web:abcdef1234567890',
  messagingSenderId: '123456789012',
  projectId: 'naumaniya-school-management',
  authDomain: 'naumaniya-school-management.firebaseapp.com',
  storageBucket: 'naumaniya-school-management.appspot.com',
);
```

## Step 6: Test Firebase Connection

1. Run your app: `flutter run -d chrome`
2. Go to the login screen
3. Create an account or sign in
4. Check if data syncs to Firebase

## Step 7: Verify Data in Firebase

1. Go to Firebase Console → Firestore Database
2. You should see collections being created:
   - `accounts` (contains user data)
   - `students` (under each user account)
   - `teachers` (under each user account)
   - `income` (under each user account)
   - `expenditure` (under each user account)

## Security Rules (Optional but Recommended)

In Firestore Database → Rules, replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /accounts/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized" error**
   - Check if `firebase_options.dart` has correct values
   - Ensure Firebase is properly initialized in `main.dart`

2. **"Permission denied" error**
   - Check Firestore security rules
   - Ensure user is authenticated

3. **"Network error"**
   - Check internet connection
   - Verify Firebase project is in the correct region

### Testing Steps:

1. **Local Storage Test**: Add some data while offline
2. **Cloud Sync Test**: Go online and check if data appears in Firebase
3. **Authentication Test**: Try creating account and logging in
4. **Data Persistence Test**: Clear browser data and check if data is restored from cloud

## Data Storage Structure

Your data will be stored in Firebase with this structure:

```
accounts/
  {user_id}/
    students/
      {student_id}/
        name: "Student Name"
        mobile: "1234567890"
        fee: "500"
        status: "Active"
        ...
    teachers/
      {teacher_id}/
        name: "Teacher Name"
        mobile: "1234567890"
        salary: "5000"
        status: "Active"
        ...
    income/
      {income_id}/
        amount: "1000"
        description: "Fee collection"
        date: "2024-01-15"
        ...
    expenditure/
      {expenditure_id}/
        amount: "500"
        description: "Utilities"
        date: "2024-01-15"
        ...
```

## Benefits of Cloud Storage

✅ **Data Backup**: Your data is safely stored in Google's cloud
✅ **Cross-Device Sync**: Access data from any device
✅ **Offline Support**: Works even without internet
✅ **Automatic Sync**: Data syncs when connection is restored
✅ **Long-term Storage**: Data persists for decades
✅ **Security**: Google's enterprise-grade security

## Cost Information

- **Free Tier**: 1GB storage, 50,000 reads/day, 20,000 writes/day
- **Typical Usage**: School management app uses minimal resources
- **Upgrade**: Only needed for very large schools (1000+ students)

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Verify configuration values are correct
3. Test with a simple data entry first
4. Check browser console for JavaScript errors 