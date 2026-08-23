// Chiffrement des clés privées des wallets générés pour chaque utilisateur.
// AES-256-GCM avec une clé dérivée de WALLET_ENCRYPTION_KEY (32 octets hex).
// Format stocké en base : "iv:authTag:ciphertext" (tout en hex).

import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';

function getKey() {
  const hex = process.env.WALLET_ENCRYPTION_KEY;
  if (!hex || hex.length !== 64) {
    throw new Error('WALLET_ENCRYPTION_KEY manquante ou invalide (32 octets hex requis)');
  }
  return Buffer.from(hex, 'hex');
}

/**
 * Chiffre une clé privée (string) pour stockage en base.
 * @param {string} privateKey
 * @returns {string} "iv:authTag:ciphertext" en hex
 */
export function encryptPrivateKey(privateKey) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGORITHM, getKey(), iv);
  const encrypted = Buffer.concat([cipher.update(privateKey, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
}

/**
 * Déchiffre une clé privée stockée en base.
 * @param {string} payload - "iv:authTag:ciphertext" en hex
 * @returns {string} clé privée en clair
 */
export function decryptPrivateKey(payload) {
  const [ivHex, authTagHex, dataHex] = payload.split(':');
  if (!ivHex || !authTagHex || !dataHex) {
    throw new Error('Format de clé privée chiffrée invalide');
  }
  const decipher = crypto.createDecipheriv(ALGORITHM, getKey(), Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(dataHex, 'hex')),
    decipher.final(),
  ]);
  return decrypted.toString('utf8');
}
