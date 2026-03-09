/**
 * Permission middleware
 * - denyIfReadonly(moduleName): for write requests, blocks users who have a readonly grant
 */
const db = require('../config/db');

async function userHasReadonlyGrant(userId, moduleName) {
  try {
    const q = `SELECT id FROM access_grants WHERE user_id = $1 AND permission = 'readonly' AND (module_name IS NULL OR module_name = $2) LIMIT 1`;
    const r = await db.query(q, [userId, moduleName]);
    return r.rows.length > 0;
  } catch (e) {
    console.error('Error checking readonly grant:', e);
    return false;
  }
}

/**
 * Middleware generator: denies write requests (non-GET) if user has readonly grant for moduleName.
 */
function denyIfReadonly(moduleName) {
  return async function (req, res, next) {
    try {
      // allow GET requests
      if (req.method === 'GET' || req.method === 'HEAD') return next();

      // require authenticated user
      const user = req.user;
      if (!user) return res.status(401).json({ success: false, error: 'Authentication required' });

      const hasReadonly = await userHasReadonlyGrant(user.id, moduleName);
      if (hasReadonly) {
        return res.status(403).json({ success: false, error: 'Write access denied: readonly only' });
      }

      return next();
    } catch (err) {
      console.error('denyIfReadonly error:', err);
      return res.status(500).json({ success: false, error: 'Permission check failed' });
    }
  };
}

module.exports = {
  denyIfReadonly,
};
