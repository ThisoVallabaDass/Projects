const admin = require('firebase-admin');

function initFirebaseAdmin() {
  if (admin.apps.length) {
    return admin;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!serviceAccountPath) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_PATH env var not set');
  }

  // Service account JSON MUST NOT be committed to git.
  // Example: FIREBASE_SERVICE_ACCOUNT_PATH=t:\\secrets\\tinytrails-service-account.json
  // eslint-disable-next-line import/no-dynamic-require, global-require
  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  return admin;
}

const firebaseAdmin = initFirebaseAdmin();
const firestore = firebaseAdmin.firestore();
const firebaseAuth = firebaseAdmin.auth();

module.exports = { firebaseAdmin, firestore, firebaseAuth };

