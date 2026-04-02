/**
 * Authentication Routes
 */

const express = require('express');
const router = express.Router();
const authService = require('../services/authService');
const { authenticate, requireAdmin, requireActive } = require('../middleware/authMiddleware');
const notificationService = require('../services/notificationService');

/**
 * POST /auth/signup
 * Register a new user
 */
router.post('/signup', async (req, res) => {
  try {
    const { name, password } = req.body;
    const result = await authService.signup(name, password);
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/login
 * Login with name and password
 */
router.post('/login', async (req, res) => {
  try {
    const { name, password } = req.body;
    const result = await authService.login(name, password);
    // Return clear JSON response and appropriate status code
    if (result && result.success) {
      return res.json(result);
    }
    return res.status(200).json({ success: false, error: result.error || 'Login failed' });
  } catch (error) {
    console.error('Auth route /login error:', error.message || error);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * POST /auth/fingerprint-login
 * Login with fingerprint token
 */
router.post('/fingerprint-login', async (req, res) => {
  try {
    const { userId, fingerprintToken } = req.body;
    const result = await authService.fingerprintLogin(userId, fingerprintToken);
    res.json(result);
  } catch (error) {
    res.status(401).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/enable-fingerprint
 * Enable fingerprint authentication
 */
router.post('/enable-fingerprint', authenticate, requireActive, async (req, res) => {
  try {
    const result = await authService.enableFingerprint(req.user.id);
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/logout
 * Logout and invalidate session
 */
router.post('/logout', authenticate, async (req, res) => {
  try {
    const result = await authService.logout(req.token);
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /auth/me
 * Get current user info
 */
router.get('/me', authenticate, requireActive, async (req, res) => {
  try {
    res.json({
      success: true,
      user: req.user,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/request-admin
 * Request admin access
 */
router.post('/request-admin', authenticate, requireActive, async (req, res) => {
  try {
    const { reason } = req.body;
    const result = await authService.requestAdminAccess(req.user.id, reason);

    // Fire push notification to all admins (non-blocking)
    notificationService.notifyAdminsNewRequest(req.user.name, reason || 'No reason provided')
      .catch(e => console.error('Push notification error:', e.message));

    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/request-access
 * Request access (full or readonly) for modules
 */
router.post('/request-access', authenticate, async (req, res) => {
  try {
    const { type, modules, reason } = req.body; // modules optional array
    const result = await authService.createAccessRequest(req.user.id, type, modules, reason);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * GET /auth/requests
 * Get current user's access requests
 */
router.get('/requests', authenticate, requireActive, async (req, res) => {
  try {
    const rows = await authService.getUserAccessRequests(req.user.id);
    res.json({ success: true, requests: rows });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * GET /auth/admin/access-requests
 * Admin: list pending access requests
 */
router.get('/admin/access-requests', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const rows = await authService.getAccessRequests();
    res.json({ success: true, requests: rows });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * POST /auth/admin/review-access-request
 * Admin: review (approve/reject) an access request
 */
router.post('/admin/review-access-request', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const { requestId, approve, grantModules } = req.body;
    const result = await authService.reviewAccessRequest(requestId, req.user.id, approve, grantModules);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * GET /auth/notifications
 * Get notifications for current user
 */
router.get('/notifications', authenticate, requireActive, async (req, res) => {
  try {
    const rows = await authService.getNotifications(req.user.id);
    res.json({ success: true, notifications: rows });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * PUT /auth/notifications/:id/read
 * Mark a notification as read
 */
router.put('/notifications/:id/read', authenticate, requireActive, async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const result = await authService.markNotificationRead(id, req.user.id);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * GET /auth/admin/requests
 * Get pending admin requests (admin only)
 */
router.get('/admin/requests', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const requests = await authService.getPendingRequests();
    res.json({
      success: true,
      requests,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/admin/review-request
 * Approve or reject admin request (admin only)
 */
router.post('/admin/review-request', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const { requestId, approve } = req.body;
    const result = await authService.reviewAdminRequest(requestId, req.user.id, approve);
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /auth/admin/users
 * Get all users (admin only)
 */
router.get('/admin/users', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const users = await authService.getAllUsers();
    res.json({
      success: true,
      users,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * PUT /auth/profile
 * Update current user's profile (name/password)
 */
router.put('/profile', authenticate, requireActive, async (req, res) => {
  try {
    const { name, password } = req.body;
    const result = await authService.updateProfile(req.user.id, name, password);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * GET /auth/admin/history
 * Get audit history for last 30 days (admin only)
 */
router.get('/admin/history', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const rows = await authService.getAuditHistory(30);
    res.json({ success: true, history: rows });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * PUT /auth/admin/user-status
 * Update user active status (admin only)
 */
router.put('/admin/user-status', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const { userId, isActive } = req.body;
    const result = await authService.updateUserStatus(userId, isActive);
    // Log who performed the action
    try { await authService.logAudit(req.user.id, 'update_user_status', userId, `Set is_active=${isActive}`); } catch (e) { console.error('Audit log failed:', e); }
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /auth/admin/user/:userId
 * Delete user (admin only)
 */
router.delete('/admin/user/:userId', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await authService.deleteUser(userId);
    try { await authService.logAudit(req.user.id, 'delete_user', userId, `Deleted user id=${userId}`); } catch (e) { console.error('Audit log failed:', e); }
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /auth/register-fcm-token
 * Save device FCM token for push notifications
 */
router.post('/register-fcm-token', authenticate, requireActive, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ success: false, error: 'fcmToken required' });
    await notificationService.saveFcmToken(req.user.id, fcmToken);
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

/**
 * POST /auth/unregister-fcm-token
 * Remove device FCM token on logout
 */
router.post('/unregister-fcm-token', authenticate, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ success: false, error: 'fcmToken required' });
    await notificationService.removeFcmToken(req.user.id, fcmToken);
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
