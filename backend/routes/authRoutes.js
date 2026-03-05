/**
 * Authentication Routes
 */

const express = require('express');
const router = express.Router();
const authService = require('../services/authService');
const { authenticate, requireAdmin, requireActive } = require('../middleware/authMiddleware');

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
    res.json(result);
  } catch (error) {
    res.status(401).json({
      success: false,
      error: error.message,
    });
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
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
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
 * PUT /auth/admin/user-status
 * Update user active status (admin only)
 */
router.put('/admin/user-status', authenticate, requireActive, requireAdmin, async (req, res) => {
  try {
    const { userId, isActive } = req.body;
    const result = await authService.updateUserStatus(userId, isActive);
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
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
