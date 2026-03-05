/**
 * Authentication Service
 * Handles user authentication, authorization, and session management
 */

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRY = '7d'; // Token expires in 7 days
const SALT_ROUNDS = 10;

class AuthService {
  /**
   * Register a new user
   */
  async signup(name, password) {
    try {
      // Validate input
      if (!name || !password) {
        throw new Error('Name and password are required');
      }

      if (password.length < 6) {
        throw new Error('Password must be at least 6 characters');
      }

      // Check if user already exists
      const existingUser = await db.query(
        'SELECT id FROM users WHERE name = $1',
        [name]
      );

      if (existingUser.rows.length > 0) {
        throw new Error('User already exists');
      }

      // Hash password
      const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

      // Create user
      const result = await db.query(
        `INSERT INTO users (name, password_hash, role, is_active) 
         VALUES ($1, $2, 'user', true) 
         RETURNING id, name, role, is_active, created_at`,
        [name, passwordHash]
      );

      const user = result.rows[0];

      // Generate token
      const token = this.generateToken(user);

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
      console.error('Signup error:', error);
      throw error;
    }
  }

  /**
   * Login user
   */
  async login(name, password) {
    try {
      // Validate input
      if (!name || !password) {
        throw new Error('Name and password are required');
      }

      // Get user
      const result = await db.query(
        'SELECT id, name, password_hash, role, is_active FROM users WHERE name = $1',
        [name]
      );

      if (result.rows.length === 0) {
        throw new Error('Invalid credentials');
      }

      const user = result.rows[0];

      // Check if user is active
      if (!user.is_active) {
        throw new Error('Account is deactivated');
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        throw new Error('Invalid credentials');
      }

      // Generate token
      const token = this.generateToken(user);

      // Save session
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
      console.error('Login error:', error);
      throw error;
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
        // Get user_id from request
        const request = await db.query(
          'SELECT user_id FROM admin_requests WHERE id = $1',
          [requestId]
        );

        if (request.rows.length > 0) {
          // Promote user to admin
          await db.query(
            'UPDATE users SET role = $1 WHERE id = $2',
            ['admin', request.rows[0].user_id]
          );
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
      return { success: true };
    } catch (error) {
      console.error('Delete user error:', error);
      throw error;
    }
  }
}

module.exports = new AuthService();
