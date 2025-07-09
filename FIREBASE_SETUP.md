# Firebase Setup Guide for Naumaniya School Management System

This guide will help you set up Firebase for your Flutter web app to enable cloud storage, authentication, and real-time data synchronization.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Your Flutter project ready

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "naumaniya-school-management")
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Add Web App to Firebase

1. In your Firebase project console, click the web icon (</>) to add a web app
2. Enter an app nickname (e.g., "Naumaniya Web")
3. Check "Also set up Firebase Hosting" if you want to deploy your app
4. Click "Register app"
5. Copy the configuration object that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  authDomain: "your-project-name.firebaseapp.com",
  projectId: "your-project-name",
  storageBucket: "your-project-name.appspot.com",
  messagingSenderId: "xxxxxxxxxxxx",
  appId: "1:xxxxxxxxxxxx:web:xxxxxxxxxxxxxxxx"
};
```

## Step 3: Update Firebase Configuration

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', // Your actual API key
  appId: '1:xxxxxxxxxxxx:web:xxxxxxxxxxxxxxxx', // Your actual app ID
  messagingSenderId: 'xxxxxxxxxxxx', // Your actual sender ID
  projectId: 'your-project-name', // Your actual project ID
  authDomain: 'your-project-name.firebaseapp.com', // Your actual auth domain
  storageBucket: 'your-project-name.appspot.com', // Your actual storage bucket
);
```

## Step 4: Enable Firebase Services

### Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users
5. Click "Done"

### Authentication
1. Go to "Authentication" in Firebase Console
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Click "Save"

### Storage (for Cloudinary integration)
1. Go to "Storage" in Firebase Console
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select a location
5. Click "Done"

## Step 5: Set Up Firestore Security Rules

1. In Firestore Database, go to "Rules" tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Specific rules for different collections
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /students/{studentId} {
      allow read, write: if request.auth != null;
    }
    
    match /teachers/{teacherId} {
      allow read, write: if request.auth != null;
    }
    
    match /income/{incomeId} {
      allow read, write: if request.auth != null;
    }
    
    match /expenditure/{expenditureId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 6: Set Up Storage Security Rules

1. In Storage, go to "Rules" tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 7: Test Firebase Connection

1. Run your Flutter app:
```bash
flutter run -d chrome
```

2. Check the console for Firebase initialization messages
3. If you see "Firebase initialized successfully", the setup is working

## Step 8: Optional - Set Up Cloudinary

If you want to use Cloudinary for image storage:

1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Create an account or sign in
3. Go to Dashboard
4. Copy your Cloud Name, API Key, and API Secret
5. Create an upload preset:
   - Go to Settings > Upload
   - Scroll to "Upload presets"
   - Click "Add upload preset"
   - Set name to "naumaniya_students"
   - Set signing mode to "Unsigned"
   - Save
6. Update `lib/services/cloudinary_service.dart` with your credentials

## Troubleshooting

### Common Issues:

1. **"Firebase not configured" error**
   - Make sure you've updated `firebase_options.dart` with your actual values
   - Check that the configuration values are correct

2. **"Permission denied" errors**
   - Check your Firestore and Storage security rules
   - Make sure authentication is properly set up

3. **"Network error" or "CORS error"**
   - Make sure your Firebase project is properly configured
   - Check that the web app is registered in Firebase Console

4. **"Invalid API key" error**
   - Verify your API key in Firebase Console
   - Make sure you're using the web app configuration, not Android/iOS

### Debug Steps:

1. Check browser console for error messages
2. Verify Firebase initialization in `main.dart`
3. Test Firebase connection with a simple read/write operation
4. Check network tab for failed requests

## Security Best Practices

1. **Never commit API keys to version control**
   - Use environment variables for production
   - Consider using Firebase App Check for additional security

2. **Use proper security rules**
   - Don't use "allow read, write: if true" in production
   - Implement proper authentication and authorization

3. **Regular security audits**
   - Review your security rules periodically
   - Monitor Firebase usage and costs

## Next Steps

After completing this setup:

1. Test all features that use Firebase (authentication, data sync, etc.)
2. Set up proper error handling for Firebase operations
3. Implement offline capabilities using Firebase's offline persistence
4. Consider setting up Firebase Analytics for usage insights
5. Plan for production deployment with proper security rules

## Support

If you encounter issues:

1. Check [Firebase Documentation](https://firebase.google.com/docs)
2. Review [Flutter Firebase Documentation](https://firebase.flutter.dev/)
3. Check Firebase Console for error logs
4. Verify your configuration matches the examples above 