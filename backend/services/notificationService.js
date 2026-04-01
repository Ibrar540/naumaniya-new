/**
 * Push Notification Service using Firebase Admin SDK
 * Sends FCM push notifications to admin devices
 */

let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  console.warn('⚠️  firebase-admin not installed. Push notifications disabled.');
  admin = null;
}

const db = require('../config/db');

// Initialize Firebase Admin (only once)
let firebaseInitialized = false;

function initFirebase() {
  if (!admin || firebaseInitialized) return;
  try {
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
      ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
      : null;

    if (!serviceAccount) {
      console.warn('⚠️  FIREBASE_SERVICE_ACCOUNT env not set. Push notifications disabled.');
      return;
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    firebaseInitialized = true;
    console.log('✅ Firebase Admin initialized');
  } catch (e) {
    console.error('❌ Firebase Admin init failed:', e.message);
  }
}

initFirebase();

/**
 * Save FCM token for a user
 */
async function saveFcmToken(userId, fcmToken) {
  try {
    await db.query(
      `INSERT INTO user_fcm_tokens (user_id, token, updated_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (user_id, token) DO UPDATE SET updated_at = NOW()`,
      [userId, fcmToken]
    );
  } catch (e) {
    console.error('❌ saveFcmToken error:', e.message);
  }
}

/**
 * Remove FCM token (on logout)
 */
async function removeFcmToken(userId, fcmToken) {
  try {
    await db.query(
      'DELETE FROM user_fcm_tokens WHERE user_id = $1 AND token = $2',
      [userId, fcmToken]
    );
  } catch (e) {
    console.error('❌ removeFcmToken error:', e.message);
  }
}

/**
 * Get all FCM tokens for all admins
 */
async function getAdminFcmTokens() {
  try {
    const result = await db.query(
      `SELECT uft.token
       FROM user_fcm_tokens uft
       JOIN users u ON u.id = uft.user_id
       WHERE u.role = 'admin' AND u.is_active = true`,
      []
    );
    return result.rows.map((r) => r.token);
  } catch (e) {
    console.error('❌ getAdminFcmTokens error:', e.message);
    return [];
  }
}

/**
 * Send push notification to a list of FCM tokens
 */
async function sendPushNotification(tokens, title, body, data = {}) {
  if (!admin || !firebaseInitialized) {
    console.warn('⚠️  Firebase not initialized — skipping push notification');
    return;
  }

  if (!tokens || tokens.length === 0) {
    console.log('ℹ️  No FCM tokens to notify');
    return;
  }

  try {
    const message = {
      notification: { title, body },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      android: {
        priority: 'high',
        notification: {
          channelId: 'admin_requests',
          priority: 'max',
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Push sent: ${response.successCount} success, ${response.failureCount} failed`);

    // Clean up invalid tokens
    response.responses.forEach(async (resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (
          errCode === 'messaging/invalid-registration-token' ||
          errCode === 'messaging/registration-token-not-registered'
        ) {
          await db.query('DELETE FROM user_fcm_tokens WHERE token = $1', [tokens[idx]]);
          console.log(`🗑️  Removed invalid token: ${tokens[idx].substring(0, 20)}...`);
        }
      }
    });
  } catch (e) {
    console.error('❌ sendPushNotification error:', e.message);
  }
}

/**
 * Notify all admins about a new admin access request
 */
async function notifyAdminsNewRequest(requesterName, reason) {
  const tokens = await getAdminFcmTokens();
  await sendPushNotification(
    tokens,
    '🔔 New Admin Request',
    `${requesterName} has requested admin access: "${reason}"`,
    { type: 'admin_request', screen: 'settings_requests' }
  );
}

module.exports = {
  saveFcmToken,
  removeFcmToken,
  notifyAdminsNewRequest,
};
