# Authentication System Documentation

## Overview

This document describes the secure authentication system implemented for the Naumaniya app with role-based access control, admin approval workflow, and optional fingerprint authentication.

## Features

### 1. User Signup and Login
- Users register with **name + password** only (no email required)
- Passwords are hashed using **bcrypt** (10 salt rounds) before storing
- Users have a role: `user` (default) or `admin`
- Regular users get immediate read-only access after signup
- JWT tokens for session management (7-day expiry)

### 2. Admin Role and Approval
- Admins have full control: add/remove users, assign admin, manage content
- Users can request admin access with a reason
- Admin access must be approved by an existing admin
- `admin_requests` table tracks requests with status: `pending`, `approved`, `rejected`
- First admin must be set manually in database for initial setup

### 3. Role-Based Access Control (RBAC)
- All admin routes protected with `requireAdmin` middleware
- Regular users have read-only access
- Authentication required for all protected endpoints
- Active user check prevents deactivated accounts from accessing

### 4. Fingerprint Login (Optional)
- Enable fingerprint after first successful login
- Secure token stored on device for biometric authentication
- Admins can require password + fingerprint for critical actions
- Uses device's native biometric authentication

## Database Schema

### Tables

#### users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_active BOOLEAN DEFAULT true,
    fingerprint_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### admin_requests
```sql
CREATE TABLE admin_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by INTEGER REFERENCES users(id),
    reason TEXT,
    UNIQUE(user_id, status)
);
```

#### auth_sessions
```sql
CREATE TABLE auth_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_info TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Backend API Endpoints

### Public Endpoints

#### POST /auth/signup
Register a new user.

**Request:**
```json
{
  "name": "john_doe",
  "password": "securepass123"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "john_doe",
    "role": "user",
    "isActive": true
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST /auth/login
Login with credentials.

**Request:**
```json
{
  "name": "john_doe",
  "password": "securepass123"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "john_doe",
    "role": "user",
    "isActive": true
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST /auth/fingerprint-login
Login with fingerprint token.

**Request:**
```json
{
  "userId": 1,
  "fingerprintToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Protected Endpoints (Require Authentication)

#### GET /auth/me
Get current user information.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "john_doe",
    "role": "user"
  }
}
```

#### POST /auth/enable-fingerprint
Enable fingerprint authentication.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "fingerprintToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST /auth/request-admin
Request admin access.

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "reason": "I need to manage budget data"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Admin access request submitted"
}
```

#### POST /auth/logout
Logout and invalidate session.

**Headers:**
```
Authorization: Bearer <token>
```

### Admin-Only Endpoints

#### GET /auth/admin/requests
Get pending admin requests.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "requests": [
    {
      "id": 1,
      "user_id": 2,
      "user_name": "john_doe",
      "reason": "I need to manage budget data",
      "requested_at": "2026-03-05T10:30:00Z"
    }
  ]
}
```

#### POST /auth/admin/review-request
Approve or reject admin request.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Request:**
```json
{
  "requestId": 1,
  "approve": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Request approved"
}
```

#### GET /auth/admin/users
Get all users.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "users": [
    {
      "id": 1,
      "name": "admin",
      "role": "admin",
      "is_active": true,
      "created_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 2,
      "name": "john_doe",
      "role": "user",
      "is_active": true,
      "created_at": "2026-03-05T10:30:00Z"
    }
  ]
}
```

#### PUT /auth/admin/user-status
Update user active status.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Request:**
```json
{
  "userId": 2,
  "isActive": false
}
```

#### DELETE /auth/admin/user/:userId
Delete a user.

**Headers:**
```
Authorization: Bearer <admin_token>
```

## Security Features

### Password Hashing
- Uses **bcrypt** with 10 salt rounds
- Passwords never stored in plain text
- One-way hashing prevents password recovery

### JWT Tokens
- Signed with secret key (set in environment variable)
- 7-day expiration by default
- Contains user ID, name, and role
- Verified on every protected request

### Session Management
- Tokens stored in `auth_sessions` table
- Tracks device info and last used time
- Automatic cleanup of expired sessions
- Logout invalidates session immediately

### Role-Based Access Control
- Middleware checks user role before allowing access
- Admin routes require `admin` role
- Active user check prevents deactivated accounts
- No self-promotion to admin without approval

### Admin Approval Workflow
1. User requests admin access with reason
2. Request stored with `pending` status
3. Admin reviews request
4. If approved, user role updated to `admin`
5. If rejected, request marked as `rejected`
6. Users cannot have multiple pending requests

## Flutter Integration

### AuthService
The `AuthService` class provides all authentication functionality:

```dart
final authService = AuthService();

// Initialize (load saved session)
await authService.initialize();

// Signup
final response = await authService.signup('john_doe', 'password123');

// Login
final response = await authService.login('john_doe', 'password123');

// Enable fingerprint
final token = await authService.enableFingerprint();

// Fingerprint login
final response = await authService.fingerprintLogin();

// Request admin
await authService.requestAdminAccess('Need to manage data');

// Logout
await authService.logout();

// Check authentication
if (authService.isAuthenticated) {
  // User is logged in
}

// Check admin
if (authService.isAdmin) {
  // User is admin
}
```

### Protected API Calls
Use `getAuthHeaders()` to include authentication:

```dart
final authService = AuthService();
final response = await http.post(
  Uri.parse('$baseUrl/ai-query'),
  headers: authService.getAuthHeaders(),
  body: jsonEncode({'message': 'Total income'}),
);
```

## Fingerprint Authentication Setup

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We need to use Face ID for secure authentication</string>
```

### Flutter Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  local_auth: ^2.1.7
```

### Implementation Example
```dart
import 'package:local_auth/local_auth.dart';

final localAuth = LocalAuthentication();

// Check if biometric is available
final canAuthenticate = await localAuth.canCheckBiometrics;

// Authenticate
final authenticated = await localAuth.authenticate(
  localizedReason: 'Please authenticate to login',
  options: const AuthenticationOptions(
    biometricOnly: true,
    stickyAuth: true,
  ),
);

if (authenticated) {
  // Proceed with fingerprint login
  await authService.fingerprintLogin();
}
```

## Initial Setup

### 1. Run Database Schema
```bash
psql -h <neon-host> -U <username> -d <database> -f database/auth_schema.sql
```

### 2. Set First Admin
The schema includes a default admin user:
- **Name:** admin
- **Password:** admin123 (CHANGE THIS IMMEDIATELY!)

To change the password:
```sql
UPDATE users 
SET password_hash = '$2b$10$<new_bcrypt_hash>' 
WHERE name = 'admin';
```

### 3. Install Backend Dependencies
```bash
cd backend
npm install bcrypt jsonwebtoken
```

### 4. Set Environment Variables
Create `backend/.env`:
```
JWT_SECRET=your-super-secret-key-change-this
DATABASE_URL=postgresql://user:pass@host/db
```

### 5. Deploy Backend
```bash
git add .
git commit -m "Add authentication system"
git push origin main
```

## Testing

### Test Signup
```bash
curl -X POST https://naumaniya-new.vercel.app/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"testuser","password":"test123"}'
```

### Test Login
```bash
curl -X POST https://naumaniya-new.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name":"testuser","password":"test123"}'
```

### Test Protected Endpoint
```bash
curl -X GET https://naumaniya-new.vercel.app/auth/me \
  -H "Authorization: Bearer <token>"
```

## Best Practices

1. **Change default admin password immediately**
2. **Use strong JWT_SECRET in production**
3. **Enable HTTPS only in production**
4. **Implement rate limiting for login attempts**
5. **Log all admin actions for audit trail**
6. **Regularly review and cleanup inactive sessions**
7. **Implement password reset functionality**
8. **Add email notifications for admin requests**
9. **Use environment variables for sensitive data**
10. **Regular security audits and updates**

## Troubleshooting

### "Invalid or expired token"
- Token may have expired (7 days)
- User may have been deactivated
- Token may have been invalidated on logout
- Solution: Login again to get new token

### "Admin access required"
- User role is not `admin`
- Solution: Request admin access and wait for approval

### "Account is deactivated"
- Admin has deactivated the account
- Solution: Contact admin to reactivate

### Fingerprint not working
- Device may not support biometrics
- Biometric permission not granted
- Fingerprint token may be invalid
- Solution: Re-enable fingerprint authentication

## Future Enhancements

1. Password reset via email
2. Two-factor authentication (2FA)
3. OAuth integration (Google, Facebook)
4. Session management dashboard
5. Audit log for all actions
6. IP-based access control
7. Device management
8. Password strength requirements
9. Account lockout after failed attempts
10. Email notifications for security events
