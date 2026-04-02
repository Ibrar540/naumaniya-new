/**
 * Authentication Service
 * Handles user authentication, authorization, and session management
 */

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRY = '7d'; // Token expires in 7 days
const SALT_ROUNDS = parseInt(process.env.SALT_ROUNDS || '10', 10);

class AuthService {
  constructor() {
    // Ensure default admin exists on startup (safe to call multiple times)
    this.ensureDefaultAdmin().catch(err => {
      console.error('Error ensuring default admin:', err.message || err);
    });
  }
  /**
   * Register — saves to pending_users only, NOT users table
   */
  async signup(name, password) {
    try {
      if (!name || !password) throw new Error('Name and password are required');
      if (password.length < 6) throw new Error('Password must be at least 6 characters');

      // Check both tables for name conflict
      const existingUser = await db.query('SELECT id FROM users WHERE name = $1', [name]);
      if (existingUser.rows.length > 0) throw new Error('Username already taken');

      const existingPending = await db.query('SELECT id FROM pending_users WHERE name = $1', [name]);
      if (existingPending.rows.length > 0) throw new Error('A registration request with this name is already pending');

      const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

      const result = await db.query(
        `INSERT INTO pending_users (name, password_hash) VALUES ($1, $2) RETURNING id, name`,
        [name, passwordHash]
      );

      const pending = result.rows[0];

      // Temp token — only valid for submitting the access type
      const token = this.generateToken({ id: pending.id, name: pending.name, role: 'pending' });

      return {
        success: true,
        pending: true,
        user: { id: pending.id, name: pending.name, role: 'pending', isActive: false },
        token,
      };
    } catch (error) {
      console.error('Signup error:', error.message);
      throw error;
    }
  }

  /**
   * Submit access type for a pending user (called right after signup)
   */
  async submitPendingRequest(pendingUserId, accessType, reason) {
    try {
      if (!['readonly', 'full'].includes(accessType)) throw new Error('Invalid access type');

      await db.query(
        `UPDATE pending_users SET access_type = $1, reason = $2 WHERE id = $3`,
        [accessType, reason || null, pendingUserId]
      );

      return { success: true, message: 'Request submitted. Waiting for admin approval.' };
    } catch (error) {
      console.error('submitPendingRequest error:', error.message);
      throw error;
    }
  }

  /**
   * Get all pending registration requests (admin only)
   */
  async getPendingRegistrations() {
    try {
      const result = await db.query(
        `SELECT id, name, access_type, reason, requested_at FROM pending_users ORDER BY requested_at ASC`
      );
      return result.rows;
    } catch (error) {
      console.error('getPendingRegistrations error:', error.message);
      throw error;
    }
  }

  /**
   * Approve pending registration — moves to users table
   */
  async approvePendingUser(pendingId, adminId) {
    try {
      const result = await db.query('SELECT * FROM pending_users WHERE id = $1', [pendingId]);
      if (result.rows.length === 0) throw new Error('Pending request not found');

      const pending = result.rows[0];

      // Check name not taken in users table
      const existing = await db.query('SELECT id FROM users WHERE name = $1', [pending.name]);
      if (existing.rows.length > 0) throw new Error('Username already exists in users');

      // Insert into users table
      const userResult = await db.query(
        `INSERT INTO users (name, password_hash, role, is_active) VALUES ($1, $2, 'user', true) RETURNING id`,
        [pending.name, pending.password_hash]
      );

      const userId = userResult.rows[0].id;

      // Delete from pending_users
      await db.query('DELETE FROM pending_users WHERE id = $1', [pendingId]);

      // Log audit
      try { await this.logAudit(adminId, 'approve_registration', userId, `Approved pending user: ${pending.name}`); } catch (_) {}

      return { success: true, message: `User ${pending.name} approved and created` };
    } catch (error) {
      console.error('approvePendingUser error:', error.message);
      throw error;
    }
  }

  /**
   * Reject pending registration — deletes from pending_users
   */
  async rejectPendingUser(pendingId, adminId) {
    try {
      const result = await db.query('SELECT name FROM pending_users WHERE id = $1', [pendingId]);
      if (result.rows.length === 0) throw new Error('Pending request not found');

      await db.query('DELETE FROM pending_users WHERE id = $1', [pendingId]);

      try { await this.logAudit(adminId, 'reject_registration', null, `Rejected pending user: ${result.rows[0].name}`); } catch (_) {}

      return { success: true, message: 'Registration request rejected and deleted' };
    } catch (error) {
      console.error('rejectPendingUser error:', error.message);
      throw error;
    }
  }

  /**
   * Login user
   */
  async login(name, password) {
    try {
      console.log(`🔐 Login attempt for user=${name} at ${new Date().toISOString()}`);
      // Validate input
      if (!name || !password) {
        return { success: false, error: 'Name and password are required' };
      }

      // Get user
      const result = await db.query(
        'SELECT id, name, password_hash, role, is_active FROM users WHERE name = $1',
        [name]
      );

      if (result.rows.length === 0) {
        console.warn(`⚠️ Login failed - user not found: ${name}`);
        return { success: false, error: 'Invalid credentials' };
      }

      const user = result.rows[0];

      // Check if user is active (approved by admin)
      if (!user.is_active) {
        // Check if there's a pending approval request
        const pendingReq = await db.query(
          `SELECT id FROM admin_requests WHERE user_id = $1 AND status = 'pending'`,
          [user.id]
        );
        if (pendingReq.rows.length > 0) {
          return { success: false, error: 'Your account is pending admin approval. Please wait.' };
        }
        return { success: false, error: 'Account is deactivated. Contact admin.' };
      }

      // Verify password
      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        console.warn(`⚠️ Login failed - invalid password for user: ${name}`);
        return { success: false, error: 'Invalid credentials' };
      }

      // Generate token
      const token = this.generateToken(user);

      // Save session (don't fail login if session save errors)
      try {
        await this.createSession(user.id, token);
      } catch (sessionErr) {
        console.error('Warning: failed to create session:', sessionErr.message || sessionErr);
      }

      console.log(`✅ Login successful for user=${name}`);

      return {
        success: true,
        user: {
          id: user.id,
          name: user.name,
          role: user.role,
          isActive: user.is_active,
        },
        token,
      };
    } catch (error) {
      console.error('Login error:', error.message || error);
      return { success: false, error: 'Internal server error' };
    }
  }

  /** Ensure default admin exists; create it if missing (hashed password) */
  async ensureDefaultAdmin() {
    try {
      const adminName = process.env.DEFAULT_ADMIN_NAME || 'admin';
      const adminPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'admin123';
      const r = await db.query('SELECT id, password_hash FROM users WHERE name = $1', [adminName]);
      if (r.rows.length > 0) {
        console.log(`ℹ️ Default admin user '${adminName}' already exists`);
        const existing = r.rows[0];
        // Check if existing hash matches the provided default password
        try {
          const matches = await bcrypt.compare(adminPassword, existing.password_hash);
          if (matches) {
            console.log(`✅ Existing admin password matches DEFAULT_ADMIN_PASSWORD`);
            return;
          } else {
            // If an explicit reset flag is provided, overwrite the password
            if (process.env.DEFAULT_ADMIN_RESET === 'true') {
              const newHash = await bcrypt.hash(adminPassword, SALT_ROUNDS);
              await db.query('UPDATE users SET password_hash = $1, role = $2, is_active = true WHERE id = $3', [newHash, 'admin', existing.id]);
              console.log(`🔧 Default admin '${adminName}' password updated due to DEFAULT_ADMIN_RESET=true`);
              return;
            }
            console.warn(`⚠️ Admin '${adminName}' exists but DEFAULT_ADMIN_PASSWORD does not match. To reset set DEFAULT_ADMIN_RESET=true env var.`);
            return;
          }
        } catch (cmpErr) {
          console.error('❌ Error comparing admin passwords:', cmpErr.message || cmpErr);
          return;
        }
      }

      const passwordHash = await bcrypt.hash(adminPassword, SALT_ROUNDS);
      const insert = await db.query(
        `INSERT INTO users (name, password_hash, role, is_active, created_at) VALUES ($1, $2, 'admin', true, CURRENT_TIMESTAMP) RETURNING id`,
        [adminName, passwordHash]
      );
      console.log(`🔧 Created default admin '${adminName}' with id=${insert.rows[0].id}`);
    } catch (err) {
      console.error('❌ Failed to ensure default admin:', err.message || err);
      throw err;
    }
  }

  /**
   * Fingerprint login
   */
  async fingerprintLogin(userId, fingerprintToken) {
    try {
      const result = await db.query(
        'SELECT id, name, role, is_active, fingerprint_token FROM users WHERE id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      const user = result.rows[0];

      if (!user.is_active) {
        throw new Error('Account is deactivated');
      }

      if (user.fingerprint_token !== fingerprintToken) {
        throw new Error('Invalid fingerprint token');
      }

      // Generate new token
      const token = this.generateToken(user);

      // Update session
      await this.createSession(user.id, token);

      return {
        success: true,
        user: {
          id: user.id,
          name: user.name,
          role: user.role,
          isActive: user.is_active,
        },
        token,
      };
    } catch (error) {
      console.error('Fingerprint login error:', error);
      throw error;
    }
  }

  /**
   * Enable fingerprint for user
   */
  async enableFingerprint(userId) {
    try {
      const fingerprintToken = this.generateFingerprintToken();

      await db.query(
        'UPDATE users SET fingerprint_token = $1 WHERE id = $2',
        [fingerprintToken, userId]
      );

      return {
        success: true,
        fingerprintToken,
      };
    } catch (error) {
      console.error('Enable fingerprint error:', error);
      throw error;
    }
  }

  /**
   * Generate JWT token
   */
  generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        name: user.name,
        role: user.role,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRY }
    );
  }

  /**
   * Generate fingerprint token
   */
  generateFingerprintToken() {
    return jwt.sign(
      { type: 'fingerprint', timestamp: Date.now() },
      JWT_SECRET,
      { expiresIn: '365d' }
    );
  }

  /**
   * Verify JWT token
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  /**
   * Create session
   */
  async createSession(userId, token, deviceInfo = null) {
    try {
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

      await db.query(
        `INSERT INTO auth_sessions (user_id, token, device_info, expires_at) 
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (token) DO UPDATE SET last_used_at = CURRENT_TIMESTAMP`,
        [userId, token, deviceInfo, expiresAt]
      );
    } catch (error) {
      console.error('Create session error:', error);
    }
  }

  /**
   * Logout (invalidate session)
   */
  async logout(token) {
    try {
      await db.query('DELETE FROM auth_sessions WHERE token = $1', [token]);
      return { success: true };
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  }

  /**
   * Request admin access
   */
  async requestAdminAccess(userId, reason) {
    try {
      // Check if user already has pending request
      const existing = await db.query(
        'SELECT id FROM admin_requests WHERE user_id = $1 AND status = $2',
        [userId, 'pending']
      );

      if (existing.rows.length > 0) {
        throw new Error('You already have a pending admin request');
      }

      // Check if user is already admin
      const user = await db.query(
        'SELECT role FROM users WHERE id = $1',
        [userId]
      );

      if (user.rows[0].role === 'admin') {
        throw new Error('You are already an admin');
      }

      // Create request
      await db.query(
        'INSERT INTO admin_requests (user_id, reason) VALUES ($1, $2)',
        [userId, reason]
      );

      return { success: true, message: 'Admin access request submitted' };
    } catch (error) {
      console.error('Request admin access error:', error);
      throw error;
    }
  }

  /**
   * Create access request (full | readonly)
   */
  async createAccessRequest(userId, type, modules = null, reason = null) {
    try {
      if (!['full', 'readonly'].includes(type)) throw new Error('Invalid request type');

      // Prevent duplicate pending requests (same user, type, modules)
      const modulesText = modules ? JSON.stringify(modules) : '[]';
      const existing = await db.query(
        `SELECT id FROM access_requests WHERE user_id = $1 AND type = $2 AND COALESCE(modules::text, '[]') = $3 AND status = 'pending'`,
        [userId, type, modulesText]
      );

      if (existing.rows.length > 0) {
        throw new Error('You already have a pending similar access request');
      }

      await db.query(
        `INSERT INTO access_requests (user_id, type, modules, reason) VALUES ($1, $2, $3::jsonb, $4)`,
        [userId, type, modules ? JSON.stringify(modules) : null, reason]
      );

      // Notify all admins about the new access request
      try {
        const admins = await db.query("SELECT id, name FROM users WHERE role = 'admin'");
        const msg = `User ${userId} requested ${type} access` + (reason ? `: ${reason}` : '');
        for (const a of admins.rows) {
          await db.query('INSERT INTO notifications (user_id, message, data) VALUES ($1, $2, $3::jsonb)', [a.id, msg, JSON.stringify({ type: 'access_request', userId, requestType: type })]);
        }
      } catch (e) {
        console.error('Failed to create admin notifications for access request:', e);
      }

      return { success: true, message: 'Access request submitted' };
    } catch (error) {
      console.error('Create access request error:', error.message || error);
      throw error;
    }
  }

  /**
   * Get current user's access requests
   */
  async getUserAccessRequests(userId) {
    try {
      const r = await db.query(
        `SELECT ar.id, ar.user_id, ar.type, ar.modules, ar.status, ar.requested_at, ar.reviewed_at, ar.reviewed_by, ar.reason, u.name as user_name
         FROM access_requests ar JOIN users u ON ar.user_id = u.id
         WHERE ar.user_id = $1 ORDER BY ar.requested_at DESC`,
        [userId]
      );
      return r.rows;
    } catch (error) {
      console.error('Get user access requests error:', error);
      throw error;
    }
  }

  /**
   * Get notifications for a user
   */
  async getNotifications(userId) {
    try {
      const r = await db.query('SELECT id, message, data, is_read, created_at FROM notifications WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
      return r.rows;
    } catch (e) {
      console.error('Get notifications error:', e);
      throw e;
    }
  }

  /**
   * Mark notification as read
   */
  async markNotificationRead(notificationId, userId) {
    try {
      await db.query('UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2', [notificationId, userId]);
      return { success: true };
    } catch (e) {
      console.error('Mark notification read error:', e);
      throw e;
    }
  }

  /**
   * Admin: list pending access requests
   */
  async getAccessRequests() {
    try {
      const r = await db.query(
        `SELECT ar.id, ar.user_id, ar.type, ar.modules, ar.status, ar.requested_at, u.name as user_name
         FROM access_requests ar JOIN users u ON ar.user_id = u.id
         WHERE ar.status = 'pending' ORDER BY ar.requested_at ASC`
      );
      return r.rows;
    } catch (error) {
      console.error('Get access requests error:', error);
      throw error;
    }
  }

  /**
   * Admin: review (approve/reject) access request
   * If approve and type == 'readonly', insert access_grants rows for modules or blanket grant if modules null
   */
  async reviewAccessRequest(requestId, adminId, approve, grantModules = null) {
    try {
      const status = approve ? 'approved' : 'rejected';

      // Get request details
      const reqRow = await db.query('SELECT * FROM access_requests WHERE id = $1', [requestId]);
      if (reqRow.rows.length === 0) throw new Error('Request not found');
      const request = reqRow.rows[0];

      // Update request status
      await db.query(
        `UPDATE access_requests SET status = $1, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = $2 WHERE id = $3`,
        [status, adminId, requestId]
      );

      if (approve) {
        // Always activate the user when any access request is approved
        await db.query('UPDATE users SET is_active = true WHERE id = $1', [request.user_id]);

        if (request.type === 'full') {
          await db.query('UPDATE users SET role = $1 WHERE id = $2', ['user', request.user_id]);
        }

        if (request.type === 'readonly') {
          // Insert grants; if modules is null, insert a blanket readonly grant with module_name NULL
          const modules = request.modules ? JSON.parse(request.modules) : null;
          if (!modules || modules.length === 0) {
            await db.query(
              `INSERT INTO access_grants (user_id, module_name, permission, granted_by) VALUES ($1, $2, $3, $4)`,
              [request.user_id, null, 'readonly', adminId]
            );
          } else {
            const insertPromises = modules.map(m => {
              return db.query(
                `INSERT INTO access_grants (user_id, module_name, permission, granted_by) VALUES ($1, $2, $3, $4)`,
                [request.user_id, m, 'readonly', adminId]
              );
            });
            await Promise.all(insertPromises);
          }
        }

        // Log audit
        await this.logAudit(adminId, 'approve_access_request', request.user_id, `Approved access request id=${requestId} type=${request.type}`);

        // Notify the requester
        try {
          const msg = `Your access request (id=${requestId}) was approved`;
          await db.query('INSERT INTO notifications (user_id, message, data) VALUES ($1, $2, $3::jsonb)', [request.user_id, msg, JSON.stringify({ type: 'access_request_review', requestId, approved: true })]);
        } catch (e) {
          console.error('Failed to notify requester about approval:', e);
        }
      } else {
        await this.logAudit(adminId, 'reject_access_request', request.user_id, `Rejected access request id=${requestId}`);
        // Notify the requester about rejection
        try {
          const msg = `Your access request (id=${requestId}) was rejected`;
          await db.query('INSERT INTO notifications (user_id, message, data) VALUES ($1, $2, $3::jsonb)', [request.user_id, msg, JSON.stringify({ type: 'access_request_review', requestId, approved: false })]);
        } catch (e) {
          console.error('Failed to notify requester about rejection:', e);
        }
      }

      return { success: true, message: `Request ${status}` };
    } catch (error) {
      console.error('Review access request error:', error);
      throw error;
    }
  }

  /**
   * Get pending admin requests (admin only)
   */
  async getPendingRequests() {
    try {
      const result = await db.query(
        `SELECT ar.id, ar.user_id, ar.reason, ar.requested_at, u.name as user_name
         FROM admin_requests ar
         JOIN users u ON ar.user_id = u.id
         WHERE ar.status = 'pending'
         ORDER BY ar.requested_at ASC`
      );

      return result.rows;
    } catch (error) {
      console.error('Get pending requests error:', error);
      throw error;
    }
  }

  /**
   * Approve/Reject admin request (admin only)
   */
  async reviewAdminRequest(requestId, adminId, approve) {
    try {
      const status = approve ? 'approved' : 'rejected';

      // Update request status
      await db.query(
        `UPDATE admin_requests 
         SET status = $1, reviewed_at = CURRENT_TIMESTAMP, reviewed_by = $2
         WHERE id = $3`,
        [status, adminId, requestId]
      );

      if (approve) {
        // Get user_id and reason from request
        const request = await db.query(
          'SELECT user_id, reason FROM admin_requests WHERE id = $1',
          [requestId]
        );

        if (request.rows.length > 0) {
          const userId = request.rows[0].user_id;
          const reason = request.rows[0].reason || '';

          // Always activate the user on approval
          await db.query('UPDATE users SET is_active = true WHERE id = $1', [userId]);

          // If this is a new account approval (not an admin promotion), keep role as 'user'
          // If the reason indicates admin promotion, promote to admin
          const isAdminPromotion = !reason.includes('New account registration');
          if (isAdminPromotion) {
            await db.query('UPDATE users SET role = $1 WHERE id = $2', ['admin', userId]);
          }

          await this.logAudit(adminId, 'approve_admin_request', userId, `Approved request id=${requestId}`);
        }
      }

      return { success: true, message: `Request ${status}` };
    } catch (error) {
      console.error('Review admin request error:', error);
      throw error;
    }
  }

  /**
   * Get all users (admin only)
   */
  async getAllUsers() {
    try {
      const result = await db.query(
        `SELECT id, name, role, is_active, created_at 
         FROM users 
         ORDER BY created_at DESC`
      );

      return result.rows;
    } catch (error) {
      console.error('Get all users error:', error);
      throw error;
    }
  }

  /**
   * Update user status (admin only)
   */
  async updateUserStatus(userId, isActive) {
    try {
      await db.query(
        'UPDATE users SET is_active = $1 WHERE id = $2',
        [isActive, userId]
      );

      // Log audit - actor unknown here; caller should log with proper admin id when used via route
      try {
        await this.logAudit(null, 'update_user_status', userId, `Set is_active=${isActive}`);
      } catch (e) {
        console.error('Audit log failed:', e);
      }

      return { success: true };
    } catch (error) {
      console.error('Update user status error:', error);
      throw error;
    }
  }

  /**
   * Delete user (admin only)
   */
  async deleteUser(userId) {
    try {
      await db.query('DELETE FROM users WHERE id = $1', [userId]);

      try {
        await this.logAudit(null, 'delete_user', userId, `Deleted user id=${userId}`);
      } catch (e) {
        console.error('Audit log failed:', e);
      }
      return { success: true };
    } catch (error) {
      console.error('Delete user error:', error);
      throw error;
    }
  }

  /**
   * Update profile (name/password) for current user
   */
  async updateProfile(userId, newName, newPassword) {
    try {
      if (!userId) throw new Error('User id is required');

      if (newPassword && newPassword.length < 6) {
        throw new Error('Password must be at least 6 characters');
      }

      if (newPassword) {
        const hash = await bcrypt.hash(newPassword, SALT_ROUNDS);
        await db.query('UPDATE users SET name = $1, password_hash = $2 WHERE id = $3', [newName, hash, userId]);
      } else {
        await db.query('UPDATE users SET name = $1 WHERE id = $2', [newName, userId]);
      }

      // Log profile update (actor is the user themselves)
      try {
        await this.logAudit(userId, 'update_profile', userId, `Updated own profile`);
      } catch (e) {
        console.error('Audit log failed:', e);
      }

      return { success: true };
    } catch (error) {
      console.error('Update profile error:', error);
      throw error;
    }
  }

  /**
   * Get audit history for last N days (default 30)
   */
  async getAuditHistory(days = 30) {
    try {
      const result = await db.query(
        `SELECT id, actor_id, actor_name, action, target_user_id, target_user_name, details, created_at
         FROM audit_logs
         WHERE created_at >= (CURRENT_TIMESTAMP - INTERVAL '${days} days')
         ORDER BY created_at DESC`,
        []
      );

      return result.rows;
    } catch (error) {
      console.error('Get audit history error:', error);
      throw error;
    }
  }

  /**
   * Insert an audit log entry. actorId may be null when caller doesn't supply it.
   */
  async logAudit(actorId, action, targetUserId = null, details = null) {
    try {
      let actorName = null;
      if (actorId) {
        try {
          const r = await db.query('SELECT name FROM users WHERE id = $1', [actorId]);
          if (r.rows.length > 0) actorName = r.rows[0].name;
        } catch (e) {
          // ignore
        }
      }

      let targetUserName = null;
      if (targetUserId) {
        try {
          const t = await db.query('SELECT name FROM users WHERE id = $1', [targetUserId]);
          if (t.rows.length > 0) targetUserName = t.rows[0].name;
        } catch (e) {}
      }

      await db.query(
        `INSERT INTO audit_logs (actor_id, actor_name, action, target_user_id, target_user_name, details)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [actorId, actorName, action, targetUserId, targetUserName, details]
      );
    } catch (error) {
      console.error('Failed to write audit log:', error);
      throw error;
    }
  }
}

module.exports = new AuthService();
