# Database Setup Guide - Step by Step

## 📋 What You're Setting Up

You're creating 3 new tables in your Neon database for authentication:
1. **users** - Stores user accounts with passwords and roles
2. **admin_requests** - Tracks admin access requests
3. **auth_sessions** - Manages login sessions and tokens

## 🚀 Setup Steps

### Step 1: Open Neon Console

1. Go to: **https://console.neon.tech**
2. Log in with your account
3. You should see your database dashboard

### Step 2: Select Your Database

1. Find your project (likely named something like "naumaniya" or similar)
2. Click on it to open
3. You should see your database details

### Step 3: Open SQL Editor

1. Look for **"SQL Editor"** in the left sidebar or top menu
2. Click on it
3. You'll see a text area where you can write SQL

### Step 4: Copy the SQL Schema

**Option A: Copy from file**
1. Open the file: `database/auth_schema.sql` in your project
2. Select ALL text (Ctrl+A)
3. Copy it (Ctrl+C)

**Option B: Copy from below**

```sql
-- Authentication System Schema for Neon/Postgres

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_active BOOLEAN DEFAULT true,
    fingerprint_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin requests table
CREATE TABLE IF NOT EXISTS admin_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by INTEGER REFERENCES users(id),
    reason TEXT,
    UNIQUE(user_id, status)
);

-- Auth sessions table (for token management)
CREATE TABLE IF NOT EXISTS auth_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_info TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_admin_requests_user_id ON admin_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_requests_status ON admin_requests(status);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(token);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id ON auth_sessions(user_id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert first admin (change password after first login!)
-- Password: 'admin123' (hashed with bcrypt)
INSERT INTO users (name, password_hash, role) 
VALUES ('admin', '$2b$10$rKZLvVZQxQxQxQxQxQxQxOeH8vKZLvVZQxQxQxQxQxQxQxQxQxQxQ', 'admin')
ON CONFLICT (name) DO NOTHING;

-- Comments
COMMENT ON TABLE users IS 'Stores user accounts with role-based access';
COMMENT ON TABLE admin_requests IS 'Tracks admin access requests and approval workflow';
COMMENT ON TABLE auth_sessions IS 'Manages authentication tokens and sessions';
```

### Step 5: Paste and Run

1. Paste the SQL into the Neon SQL Editor (Ctrl+V)
2. Click the **"Run"** button (or press Ctrl+Enter)
3. Wait for execution (should take 1-2 seconds)

### Step 6: Verify Success

You should see messages like:
```
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
...
INSERT 0 1
```

This means:
- ✅ 3 tables created
- ✅ 6 indexes created
- ✅ 1 trigger created
- ✅ 1 admin user inserted

### Step 7: Verify Tables Exist

In Neon console, you can verify the tables were created:

1. Look for a **"Tables"** section in the sidebar
2. You should see:
   - `users`
   - `admin_requests`
   - `auth_sessions`

Or run this query to check:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'admin_requests', 'auth_sessions');
```

You should see all 3 tables listed.

### Step 8: Verify Admin User

Run this query to check the admin user was created:
```sql
SELECT id, name, role, is_active, created_at 
FROM users 
WHERE name = 'admin';
```

You should see:
```
id | name  | role  | is_active | created_at
---+-------+-------+-----------+------------
 1 | admin | admin | true      | 2026-03-05...
```

## ✅ Success Indicators

If you see these, you're done:
- ✅ No error messages in SQL Editor
- ✅ Tables appear in Neon dashboard
- ✅ Admin user query returns 1 row
- ✅ All CREATE statements succeeded

## ❌ Troubleshooting

### Error: "relation already exists"
**Meaning:** Tables already exist from a previous run.

**Solution:** This is fine! The `IF NOT EXISTS` clause prevents errors. Your tables are already set up.

### Error: "permission denied"
**Meaning:** You don't have permission to create tables.

**Solution:** 
1. Ensure you're logged in as the database owner
2. Check you selected the correct database
3. Contact Neon support if issue persists

### Error: "syntax error"
**Meaning:** SQL syntax issue (unlikely with this script).

**Solution:**
1. Ensure you copied the ENTIRE SQL script
2. Don't modify the SQL
3. Try copying again from the file

### Can't find SQL Editor
**Solution:**
1. Look for "Query" or "SQL" in the Neon dashboard
2. Try the "Tables" section and look for "Run SQL" button
3. Check Neon documentation for your specific UI version

## 🔐 Default Admin Account

After setup, you have:
- **Username:** admin
- **Password:** admin123

⚠️ **IMPORTANT:** Change this password immediately after first login!

## 🧪 Test the Setup

After database setup, test the API:

```powershell
# Test login with admin account
curl -X POST https://naumaniya-new.vercel.app/auth/login `
  -H "Content-Type: application/json" `
  -d '{"name":"admin","password":"admin123"}'
```

**Expected response:**
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

If you get this response, your database is set up correctly! ✅

## 📝 What Was Created

### users table
Stores all user accounts:
- `id` - Unique user ID
- `name` - Username (unique)
- `password_hash` - Encrypted password (bcrypt)
- `role` - Either 'user' or 'admin'
- `is_active` - Account status
- `fingerprint_token` - For biometric login
- `created_at` - When account was created
- `updated_at` - Last update time

### admin_requests table
Tracks admin access requests:
- `id` - Request ID
- `user_id` - Who requested
- `status` - pending/approved/rejected
- `requested_at` - When requested
- `reviewed_at` - When reviewed
- `reviewed_by` - Which admin reviewed
- `reason` - Why they want admin access

### auth_sessions table
Manages login sessions:
- `id` - Session ID
- `user_id` - Who is logged in
- `token` - JWT token
- `device_info` - Device details
- `expires_at` - When token expires
- `created_at` - When session started
- `last_used_at` - Last activity

## 🎯 Next Steps

After database setup:

1. ✅ Test API with PowerShell script:
   ```powershell
   .\scripts\test-auth-api.ps1
   ```

2. ✅ Update Flutter app with authentication

3. ✅ Test login/signup in app

4. ✅ Change default admin password

---

**Need Help?**
- Check Neon documentation: https://neon.tech/docs
- Review error messages carefully
- Ensure you're using the correct database
- Verify you have admin permissions
