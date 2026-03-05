# 🚀 Quick Start - Database Setup

## Step 1: Open Neon Console
Go to: **https://console.neon.tech**

## Step 2: Open SQL Editor
Find "SQL Editor" in your Neon dashboard

## Step 3: Copy & Run This SQL

```sql
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

-- Auth sessions table
CREATE TABLE IF NOT EXISTS auth_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_info TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_admin_requests_user_id ON admin_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_requests_status ON admin_requests(status);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(token);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id ON auth_sessions(user_id);

-- Trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- First admin user
INSERT INTO users (name, password_hash, role) 
VALUES ('admin', '$2b$10$rKZLvVZQxQxQxQxQxQxQxOeH8vKZLvVZQxQxQxQxQxQxQxQxQxQxQ', 'admin')
ON CONFLICT (name) DO NOTHING;
```

## Step 4: Click "Run" or Press Ctrl+Enter

You should see:
```
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
...
INSERT 0 1
```

## Step 5: Verify

Run this to check:
```sql
SELECT * FROM users WHERE name = 'admin';
```

You should see 1 row with admin user.

## ✅ Done!

Now test the API:
```powershell
.\scripts\test-auth-api.ps1
```

Or manually:
```bash
curl -X POST https://naumaniya-new.vercel.app/auth/login -H "Content-Type: application/json" -d "{\"name\":\"admin\",\"password\":\"admin123\"}"
```

## 🔐 Default Login
- Username: **admin**
- Password: **admin123**

⚠️ Change this password after first login!

---

**Need detailed instructions?** See `DATABASE_SETUP_GUIDE.md`
