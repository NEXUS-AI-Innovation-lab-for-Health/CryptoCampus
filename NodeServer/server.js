/* ========================================
   CRYPTOCAMPUS - SERVEUR API
   ========================================
   Ce serveur expose uniquement les routes /api/*
   Le frontend est servi par un container Nginx séparé
   ======================================== */

import express from 'express';
import { Pool } from 'pg';
import { fileURLToPath } from 'url';
import { dirname, join, basename } from 'path';
import { readFileSync, existsSync, mkdirSync, unlinkSync } from 'fs';
import session from 'express-session';
import connectPgSimple from 'connect-pg-simple';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import cors from 'cors';
import multer from 'multer';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import 'dotenv/config';
import { createServer } from 'http';
import { Server } from 'socket.io';

// Services métier
import { getAllAccounts, sendTransaction, getBalance, getTransactionDetails, createAccount } from './Api/blockchain.js';
import { initQdrantCollection, indexListing, searchListings, getAllListings, deleteListing } from './Api/qdrant-service.js';
import { analyzeCVAndGenerateSuggestions } from './Api/cv-analyzer.js';
import { getLinkedInAuthorizationUrl, exchangeCodeForToken, fetchLinkedInProfile } from './Api/linkedin-auth.js';
import { correctListingText, translateListingText } from './Api/mistral-service.js';
import { encryptPrivateKey, decryptPrivateKey } from './Api/wallet-crypto.js';

/* ========================================
   CONFIGURATION DE BASE
   ======================================== */

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const httpServer = createServer(app);

// Mêmes origines autorisées que le middleware CORS Express plus bas (FRONTEND_ORIGINS) :
// une connexion Socket.io authentifiée par cookie doit passer les mêmes règles CORS que
// le reste de l'API ("origin: '*' + credentials" est invalide et rejeté par les
// navigateurs pour les échanges authentifiés cross-origin, voir plus bas).
const socketAllowedOrigins = (process.env.FRONTEND_ORIGINS || 'http://localhost,http://127.0.0.1')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

// path: '/api/socket.io' pour rester sous le préfixe déjà proxifié par Nginx (voir
// Application/Frontend/nginx.conf) au lieu du défaut '/socket.io/', qui ne serait routé
// vers ce serveur ni en prod ni en dev.
const io = new Server(httpServer, {
  path: '/api/socket.io',
  cors: {
    origin: (origin, callback) => {
      if (!origin || socketAllowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      callback(new Error('Origin non autorisée par CORS'));
    },
    credentials: true,
  },
});

const PORT = process.env.PORT || 3000;

// Middlewares généraux
app.use(helmet({
  // Désactivé : ce serveur n'expose pas de pages HTML avec scripts/styles inline
  // (le frontend est servi séparément par Nginx), sauf Swagger UI qui a besoin
  // d'inline scripts/styles pour fonctionner.
  contentSecurityPolicy: false,
}));
app.use(express.json());

// CORS : seules les origines listées dans FRONTEND_ORIGINS peuvent appeler l'API avec
// les cookies de session. "origin: '*' + credentials: true" (config précédente) est
// invalide selon la spec CORS et est rejeté par les navigateurs pour les requêtes
// authentifiées cross-origin.
const allowedOrigins = (process.env.FRONTEND_ORIGINS || 'http://localhost,http://127.0.0.1')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    // Pas d'en-tête Origin (clients non-navigateur : mobile, curl, server-to-server) => autorisé
    if (!origin || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    callback(new Error('Origin non autorisée par CORS'));
  },
  credentials: true,
}));

// Rate limiting global sur l'API (anti-abus). Configurable (voir authLimiter plus bas)
// pour ne pas gêner la suite de tests automatisés, qui envoie beaucoup de requêtes
// en parallèle sans que ce soit un abus réel.
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: process.env.API_RATE_LIMIT ? Number(process.env.API_RATE_LIMIT) : 300,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Rate limiting strict sur les routes sensibles (anti brute-force / anti-spam)
// Limite configurable (utile pour les tests automatisés, qui créent beaucoup de
// comptes en peu de temps) : reste à 20/15min par défaut en production.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: process.env.AUTH_RATE_LIMIT ? Number(process.env.AUTH_RATE_LIMIT) : 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Trop de tentatives, veuillez réessayer plus tard' },
});

/* ========================================
   CONNEXION BASE DE DONNÉES
   ======================================== */

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});

// Test de connexion
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL connection error:', err);
});

/* ========================================
   GESTION DES SESSIONS
   ======================================== */

if (!process.env.SESSION_SECRET) {
  console.warn('⚠️  SESSION_SECRET non définie dans l\'environnement : générez-en une et placez-la dans .env (voir .env.example)');
}

const PgSession = connectPgSimple(session);

// Nommé (plutôt qu'inline dans app.use) pour pouvoir être réutilisé tel quel par
// Socket.io (voir plus bas, io.engine.use) : la messagerie temps réel s'appuie sur la
// même session que le reste de l'API, pas un mécanisme d'auth séparé.
const sessionMiddleware = session({
  store: new PgSession({
    pool,
    tableName: 'user_sessions',
    createTableIfMissing: true,
  }),
  name: 'sessionId',
  // Un SESSION_SECRET est requis en production : ce repli local ne sert qu'à ne pas
  // planter en dev si .env n'est pas encore configuré.
  secret: process.env.SESSION_SECRET || crypto.randomBytes(64).toString('hex'),
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // true en production avec HTTPS
    sameSite: 'lax',
    maxAge: 1000 * 60 * 60, // 1 heure
  },
});

app.use(sessionMiddleware);

// Socket.io partage la même session Express (même cookie sessionId) : pas de mécanisme
// d'auth séparé pour la messagerie temps réel. io.engine.use applique le middleware à la
// poignée de main WebSocket exactement comme app.use le fait pour les requêtes HTTP.
io.engine.use(sessionMiddleware);

io.use((socket, next) => {
  const userId = socket.request.session?.userId;
  if (!userId) {
    return next(new Error('unauthorized'));
  }
  socket.userId = userId;
  next();
});

io.on('connection', (socket) => {
  // Chaque utilisateur rejoint une "room" personnelle (son propre user_id) : le serveur
  // peut ainsi notifier quelqu'un (io.to(userId).emit(...)) sans jamais avoir à suivre
  // quel(s) socket.id lui appartien(nen)t (multi-onglets, reconnexions...).
  socket.join(socket.userId);
  console.log(`🔌 Socket connecté : utilisateur ${socket.userId}`);

  socket.on('disconnect', () => {
    console.log(`🔌 Socket déconnecté : utilisateur ${socket.userId}`);
  });
});

/* ========================================
   MIDDLEWARE D'AUTHENTIFICATION
   ======================================== */

function authGuard(options) {
  return (req, res, next) => {
    const isLogged = !!req.session.userId;

    if (options.mustBeLogged && !isLogged) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (options.mustBeGuest && isLogged) {
      return res.status(403).json({ error: 'Already authenticated' });
    }

    next();
  };
}

// Middleware: réservé aux comptes ADMIN (vérifie le rôle en base, pas seulement la session)
function requireAdmin() {
  return async (req, res, next) => {
    if (!req.session.userId) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    try {
      const result = await pool.query('SELECT role FROM users WHERE user_id = $1', [req.session.userId]);
      if (result.rows.length === 0 || result.rows[0].role !== 'ADMIN') {
        return res.status(403).json({ error: 'Réservé aux administrateurs' });
      }
      next();
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };
}

function normalizeTutorPlaces(inputPlaces) {
  if (!Array.isArray(inputPlaces)) {
    return ['Visio'];
  }

  const cleaned = inputPlaces
    .map((place) => (typeof place === 'string' ? place.trim() : ''))
    .filter((place) => place.length > 0)
    .slice(0, 10);

  return cleaned.length > 0 ? cleaned : ['Visio'];
}

function normalizeLessonMode(mode) {
  const normalized = typeof mode === 'string' ? mode.trim() : '';
  return normalized.length > 0 ? normalized : 'Visio';
}

function normalizeVisioTool(tool) {
  const normalized = typeof tool === 'string' ? tool.trim() : '';
  return normalized.length > 0 ? normalized : 'Zoom';
}

// Corrige l'orthographe/grammaire d'une annonce via l'IA, sans jamais faire échouer
// la création/modification si Mistral est indisponible (clé manquante, quota, panne...).
async function safeCorrectListingText(title, description) {
  try {
    const corrected = await correctListingText({ title, description });
    return {
      title: corrected.title || title,
      description: corrected.description || description,
      corrected: corrected.hasChanges,
    };
  } catch (error) {
    console.warn('⚠️ Correction IA indisponible, texte original conservé:', error.message);
    return { title, description, corrected: false };
  }
}

// Traduit une annonce dans toutes les langues du site, sans jamais faire échouer la
// création/modification si Mistral est indisponible (l'annonce reste alors uniquement en français).
async function safeTranslateListingText(title, description) {
  try {
    return await translateListingText({ title, description });
  } catch (error) {
    console.warn('⚠️ Traduction IA indisponible, annonce indexée en français uniquement:', error.message);
    return null;
  }
}

async function ensureFeatureSchema() {
  const statements = [
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS lesson_mode VARCHAR(30) DEFAULT 'Visio'`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS visio_tool VARCHAR(60) DEFAULT 'Zoom'`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS lesson_places TEXT[] DEFAULT ARRAY['Visio']::TEXT[]`,
    `CREATE TABLE IF NOT EXISTS listing_interests (
      listing_id BIGINT NOT NULL,
      student_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
      created_at TIMESTAMP DEFAULT NOW(),
      PRIMARY KEY (listing_id, student_user_id)
    )`,
    `CREATE TABLE IF NOT EXISTS listing_favorites (
      listing_id BIGINT NOT NULL,
      student_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
      created_at TIMESTAMP DEFAULT NOW(),
      PRIMARY KEY (listing_id, student_user_id)
    )`,
    `CREATE INDEX IF NOT EXISTS idx_listing_interests_listing_id
     ON listing_interests (listing_id)`,
    `CREATE INDEX IF NOT EXISTS idx_listing_favorites_listing_id
     ON listing_favorites (listing_id)`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS referral_code VARCHAR(20) UNIQUE`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES users(user_id)`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS linkedin_email VARCHAR`,
    `ALTER TABLE users
     ADD COLUMN IF NOT EXISTS avatar_url TEXT`,
    `CREATE TABLE IF NOT EXISTS beneficiaries (
      beneficiary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      owner_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
      label VARCHAR(100) NOT NULL,
      address VARCHAR(100) NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )`,
    `CREATE INDEX IF NOT EXISTS idx_beneficiaries_owner
     ON beneficiaries (owner_user_id)`,
    `ALTER TABLE wallets
     ADD COLUMN IF NOT EXISTS private_key_encrypted TEXT`,
  ];

  for (const sql of statements) {
    await pool.query(sql);
  }

  await pool.query(`
    UPDATE users
    SET lesson_mode = COALESCE(lesson_mode, 'Visio'),
        visio_tool = COALESCE(visio_tool, 'Zoom'),
        lesson_places = COALESCE(lesson_places, ARRAY['Visio']::TEXT[])
  `);

  // Générer un code de parrainage pour les comptes existants qui n'en ont pas encore
  const usersWithoutCode = await pool.query(
    'SELECT user_id FROM users WHERE referral_code IS NULL'
  );
  for (const row of usersWithoutCode.rows) {
    const code = await generateUniqueReferralCode();
    await pool.query('UPDATE users SET referral_code = $1 WHERE user_id = $2', [code, row.user_id]);
  }

  console.log('✅ Feature schema ensured (locations, favorites, interests, referrals, beneficiaries)');
}

// Génère un code de parrainage lisible (8 caractères alphanumériques majuscules)
function generateReferralCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans caractères ambigus (0/O, 1/I)
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

// Génère un code de parrainage garanti unique en base
async function generateUniqueReferralCode() {
  for (let attempts = 0; attempts < 10; attempts++) {
    const code = generateReferralCode();
    const existing = await pool.query('SELECT 1 FROM users WHERE referral_code = $1', [code]);
    if (existing.rows.length === 0) return code;
  }
  throw new Error('Impossible de générer un code de parrainage unique');
}

/* ========================================
   PARRAINAGE : détermine le rôle à la création d'un compte
   - Un code de parrainage valide => compte ÉTUDIANT (parrainé)
   - Pas de code => compte TUTEUR
   - ADMIN n'est jamais attribuable via ce mécanisme
   ======================================== */
async function resolveRoleFromReferral(desiredRoleRaw, referralCodeRaw) {
  const desiredRole = typeof desiredRoleRaw === 'string' ? desiredRoleRaw.trim().toUpperCase() : '';

  if (desiredRole === 'TUTOR') {
    return { role: 'TUTOR', referredBy: null };
  }

  if (desiredRole === 'STUDENT') {
    const referralCode = typeof referralCodeRaw === 'string' ? referralCodeRaw.trim().toUpperCase() : '';

    if (!referralCode) {
      const err = new Error('Un code de parrainage est requis pour créer un compte étudiant');
      err.statusCode = 400;
      throw err;
    }

    const referrer = await pool.query(
      'SELECT user_id FROM users WHERE referral_code = $1',
      [referralCode]
    );

    if (referrer.rows.length === 0) {
      const err = new Error('Code de parrainage invalide');
      err.statusCode = 400;
      throw err;
    }

    return { role: 'STUDENT', referredBy: referrer.rows[0].user_id };
  }

  const err = new Error('Choisissez si vous créez un compte étudiant ou tuteur');
  err.statusCode = 400;
  throw err;
}

// Ajoute le nouvel étudiant parrainé au carnet de bénéficiaires de son parrain
// (pour que le tuteur puisse lui envoyer des CCT rapidement, ex. lors d'un test).
async function addStudentAsBeneficiary(tutorUserId, studentUserId, studentLabel) {
  try {
    const walletResult = await pool.query(
      `SELECT public_address FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
      [studentUserId]
    );
    if (walletResult.rows.length === 0) return;

    const address = walletResult.rows[0].public_address;
    await pool.query(
      `INSERT INTO beneficiaries (owner_user_id, label, address) VALUES ($1, $2, $3)`,
      [tutorUserId, studentLabel || 'Filleul(e)', address]
    );
  } catch (error) {
    // Non bloquant : l'échec de cet ajout ne doit pas faire échouer l'inscription
    console.error('Erreur ajout automatique du filleul en bénéficiaire:', error.message);
  }
}

/* ========================================
   HELPER: ASSIGNER ADRESSE BLOCKCHAIN
   ======================================== */

async function assignBlockchainAddress(userId) {
  try {
    // Vérifier si l'utilisateur a déjà une adresse
    const existingWallet = await pool.query(
      'SELECT wallet_id FROM wallets WHERE user_id = $1 AND blockchain = $2',
      [userId, 'ethereum']
    );

    if (existingWallet.rows.length > 0) {
      return; // L'utilisateur a déjà un wallet
    }

    const userResult = await pool.query('SELECT role FROM users WHERE user_id = $1', [userId]);
    const role = userResult.rows[0]?.role;

    // Chaque utilisateur reçoit sa propre adresse générée (plutôt qu'une des 10 adresses
    // de développement de Ganache) : plus de limite sur le nombre de comptes, plus de
    // wallet partagé entre plusieurs utilisateurs.
    const account = createAccount();
    const encryptedKey = encryptPrivateKey(account.privateKey);

    const walletInsert = await pool.query(
      `INSERT INTO wallets (user_id, public_address, blockchain, private_key_encrypted, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       RETURNING wallet_id`,
      [userId, account.address, 'ethereum', encryptedKey]
    );

    console.log(`✅ Wallet créé: ${account.address} -> User ${userId} (${role})`);

    // Un tuteur démarre avec 1000 CCT (financés par la trésorerie) ; un étudiant parrainé
    // démarre à 0 (adresse neuve jamais financée).
    if (role === 'TUTOR') {
      const treasuryAddress = await getShopTreasuryAddress();
      const fundResult = await sendTransaction(treasuryAddress, account.address, 1000);

      await pool.query(
        `INSERT INTO transactions (tx_hash, from_wallet, to_wallet, amount, status, type)
         VALUES ($1, NULL, $2, $3, 'CONFIRMED', 'MINT')`,
        [fundResult.transactionHash, walletInsert.rows[0].wallet_id, 1000]
      );

      console.log(`💰 1000 CCT crédités au tuteur ${userId}`);
    }
  } catch (error) {
    console.error('Erreur lors de l\'assignation d\'adresse blockchain:', error);
    throw error;
  }
}

// Récupère l'adresse et la clé privée déchiffrée du wallet d'un utilisateur, pour signer
// une transaction en son nom. `privateKey` est `null` pour un ancien wallet partagé
// (géré/déverrouillé directement par le nœud Ganache, aucune clé stockée).
async function getSenderWallet(userId) {
  const result = await pool.query(
    `SELECT wallet_id, public_address, private_key_encrypted
     FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
    [userId]
  );

  if (result.rows.length === 0) return null;

  const row = result.rows[0];
  return {
    walletId: row.wallet_id,
    address: row.public_address,
    privateKey: row.private_key_encrypted ? decryptPrivateKey(row.private_key_encrypted) : null,
  };
}

// Résout le wallet_id correspondant à une adresse publique, si elle appartient à un
// utilisateur de la plateforme (sinon null : l'adresse est un bénéficiaire externe).
async function findWalletIdByAddress(address) {
  const result = await pool.query(
    `SELECT wallet_id FROM wallets WHERE LOWER(public_address) = LOWER($1) LIMIT 1`,
    [address]
  );
  return result.rows[0]?.wallet_id || null;
}

// Adresse Ganache réservée pour recevoir les paiements de la boutique (index 0)
async function getShopTreasuryAddress() {
  const ganacheAccounts = await getAllAccounts();
  if (!ganacheAccounts || ganacheAccounts.length === 0) {
    throw new Error('Aucun compte Ganache disponible');
  }
  return ganacheAccounts[0].address;
}

// Calcule le solde réel (blockchain) et les statistiques d'un utilisateur.
// Utilisé par /api/profile et /api/balance pour qu'ils affichent toujours la même chose.
async function getWalletBalanceAndStats(userId) {
  let balance = 0;
  let blockchainAddress = null;

  let walletResult = await pool.query(
    `SELECT public_address FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
    [userId]
  );

  if (walletResult.rows.length === 0) {
    try {
      await assignBlockchainAddress(userId);
      walletResult = await pool.query(
        `SELECT public_address FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
        [userId]
      );
    } catch (assignError) {
      console.error('Erreur création wallet:', assignError);
    }
  }

  let walletId = null;
  if (walletResult.rows.length > 0) {
    blockchainAddress = walletResult.rows[0].public_address;
    try {
      const balanceData = await getBalance(blockchainAddress);
      balance = parseFloat(balanceData.balanceEth);
    } catch (balanceError) {
      console.error('Erreur récupération solde Ganache:', balanceError);
      balance = 0;
    }

    const walletIdResult = await pool.query(
      `SELECT wallet_id FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
      [userId]
    );
    walletId = walletIdResult.rows[0]?.wallet_id || null;
  }

  const helpedCountResult = await pool.query(
    `SELECT COUNT(DISTINCT sp.user_id) as count
     FROM service_participations sp
     JOIN services s ON sp.service_id = s.service_id
     WHERE s.created_by = $1 AND sp.status = 'CONFIRMED'`,
    [userId]
  );
  const helpedCount = parseInt(helpedCountResult.rows[0]?.count || 0);

  let totalEarned = 0;
  if (walletId) {
    const earnedResult = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) as total
       FROM transactions
       WHERE to_wallet = $1 AND status = 'CONFIRMED'`,
      [walletId]
    );
    totalEarned = parseFloat(earnedResult.rows[0]?.total || 0);
  }

  const requestsCreatedResult = await pool.query(
    `SELECT COUNT(*) as count FROM services WHERE created_by = $1`,
    [userId]
  );
  const requestsCreated = parseInt(requestsCreatedResult.rows[0]?.count || 0);

  return {
    balance,
    blockchainAddress,
    stats: { helpedCount, totalEarned, requestsCreated },
  };
}

// Historique des transactions d'un utilisateur (crédits, envois/réceptions de CCT, achats),
// dans le format déjà consommé par la page Solde du frontend.
async function getTransactionHistory(userId) {
  const result = await pool.query(
    `SELECT t.transaction_id, t.amount, t.type, t.status, t.created_at,
            fu.user_id AS from_user_id, fu.first_name AS from_first_name, fu.last_name AS from_last_name,
            tu.user_id AS to_user_id, tu.first_name AS to_first_name, tu.last_name AS to_last_name
     FROM transactions t
     LEFT JOIN wallets fw ON t.from_wallet = fw.wallet_id
     LEFT JOIN users fu ON fw.user_id = fu.user_id
     LEFT JOIN wallets tw ON t.to_wallet = tw.wallet_id
     LEFT JOIN users tu ON tw.user_id = tu.user_id
     WHERE (fu.user_id = $1 OR tu.user_id = $1) AND t.status != 'FAILED'
     ORDER BY t.created_at DESC
     LIMIT 50`,
    [userId]
  );

  const counterpartyName = (firstName, lastName, fallback) => {
    const name = `${firstName || ''} ${lastName || ''}`.trim();
    return name || fallback;
  };

  return result.rows.map((row) => {
    const isIncoming = row.to_user_id === userId;
    const amount = isIncoming ? parseFloat(row.amount) : -parseFloat(row.amount);

    let description;
    if (row.type === 'MINT') {
      description = 'Crédit de bienvenue (1000 CCT)';
    } else if (row.type === 'BURN') {
      description = 'Achat boutique';
    } else if (isIncoming) {
      description = `Reçu de ${counterpartyName(row.from_first_name, row.from_last_name, 'un autre utilisateur')}`;
    } else {
      description = `Envoyé à ${counterpartyName(row.to_first_name, row.to_last_name, 'une adresse externe')}`;
    }

    return {
      id: row.transaction_id,
      description,
      date: row.created_at,
      amount,
    };
  });
}

// Catalogue de la boutique (source unique utilisée par /api/shop et /api/purchase)
const SHOP_PRODUCTS = [
  {
    id: 1,
    name: 'Amazon Voucher',
    description: '$20 Amazon Gift Card',
    price: 100,
    category: 'giftcard',
    emoji: '🎁',
  },
  {
    id: 2,
    name: 'Netflix Pass',
    description: '1 Month Netflix Premium',
    price: 80,
    category: 'premium',
    emoji: '📺',
  },
];

/* ========================================
   CONFIGURATION MULTER (Upload de fichiers)
   ======================================== */

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Seuls les fichiers PDF sont acceptés'));
    }
  }
});

/* ========================================
   PHOTOS DE PROFIL
   ======================================== */

const AVATAR_MIME_TO_EXT = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

const avatarsDir = join(__dirname, 'uploads', 'avatars');
mkdirSync(avatarsDir, { recursive: true });

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, avatarsDir),
  filename: (req, file, cb) => {
    const ext = AVATAR_MIME_TO_EXT[file.mimetype] || '.jpg';
    cb(null, `${req.session.userId}-${Date.now()}${ext}`);
  },
});

const uploadAvatar = multer({
  storage: avatarStorage,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB max
  fileFilter: (req, file, cb) => {
    if (AVATAR_MIME_TO_EXT[file.mimetype]) {
      cb(null, true);
    } else {
      cb(new Error('Formats acceptés : JPG, PNG, WEBP'));
    }
  },
});

// Sert les avatars uploadés. Passe par /api/ (proxifié par Nginx vers ce serveur),
// pas besoin de toucher à la config Nginx du frontend.
app.use('/api/uploads', express.static(join(__dirname, 'uploads')));

function deleteAvatarFile(avatarUrl) {
  if (!avatarUrl || !avatarUrl.startsWith('/api/uploads/avatars/')) return;
  try {
    unlinkSync(join(avatarsDir, basename(avatarUrl)));
  } catch (error) {
    // Fichier déjà absent ou verrouillé : non bloquant
  }
}

/* ========================================
   ROUTES API - AUTHENTIFICATION
   ======================================== */

// Index API - Documentation des endpoints
app.get('/api', (req, res) => {
  /* #swagger.tags = ['General'] */
  res.json({
    message: 'CryptoCampus API - Serveur Unifié',
    version: '2.0.0',
    endpoints: {
      authentication: {
        'GET /api/check-auth': 'Vérifier le statut d\'authentification',
        'POST /api/login': 'Connexion utilisateur',
        'POST /api/logout': 'Déconnexion',
        'POST /api/register': 'Créer un nouveau compte',
        'GET /api/profile': 'Obtenir le profil (authentification requise)'
      },
      users: {
        'GET /api/users': 'Liste tous les utilisateurs',
        'GET /api/users/:user_id': 'Obtenir un utilisateur par ID',
        'PUT /api/users/:user_id': 'Mettre à jour un utilisateur',
        'DELETE /api/users/:user_id': 'Supprimer un utilisateur'
      },
      availability: {
        'GET /api/availability': 'Lister les créneaux disponibles (filtre: ?listing_id=xxx ou ?tutor_user_id=xxx)',
        'POST /api/availability': 'Créer un ou plusieurs créneaux de disponibilité (tuteur uniquement)',
        'DELETE /api/availability/:slot_id': 'Supprimer un créneau (tuteur propriétaire uniquement)'
      },
      bookings: {
        'GET /api/bookings': 'Liste toutes les réservations (optionnel: ?user_id=xxx)',
        'GET /api/bookings/:booking_id': 'Obtenir une réservation par ID',
        'POST /api/bookings': 'Créer une nouvelle réservation (via slot_ids ou manuellement)',
        'PUT /api/bookings/:booking_id': 'Mettre à jour une réservation',
        'PATCH /api/bookings/:booking_id/status': 'Mettre à jour le statut d\'une réservation',
        'DELETE /api/bookings/:booking_id': 'Supprimer une réservation'
      },
      blockchain: {
        'GET /api/blockchain/accounts': 'Liste tous les comptes Ethereum',
        'GET /api/blockchain/balance/:address': 'Obtenir le solde d\'une adresse',
        'POST /api/blockchain/transaction': 'Créer une transaction',
        'GET /api/blockchain/transaction/:txHash': 'Obtenir les détails d\'une transaction'
      },
      listings: {
        'GET /api/listings': 'Liste toutes les annonces',
        'GET /api/listings/search?query=xxx': 'Recherche sémantique d\'annonces',
        'POST /api/listings': 'Créer une nouvelle annonce',
        'DELETE /api/listings/:listing_id': 'Supprimer une annonce'
      },
      services: {
        'POST /api/analyze-cv': 'Analyser un CV (PDF) et obtenir des suggestions'
      }
    },
    documentation: 'https://github.com/ThomasLeBg94/SAE5A01'
  });
});

// Vérifier le statut d'authentification
app.get('/api/check-auth', async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  const isAuthenticated = !!req.session.userId;
  
  if (isAuthenticated && req.session.userId) {
    try {
      const result = await pool.query(
        'SELECT role, email, avatar_url FROM users WHERE user_id = $1',
        [req.session.userId]
      );

      if (result.rows.length > 0) {
        return res.json({
          isAuthenticated,
          userId: req.session.userId,
          role: result.rows[0].role,
          email: result.rows[0].email,
          avatarUrl: result.rows[0].avatar_url,
        });
      }
    } catch (error) {
      console.error('Error fetching user role:', error);
    }
  }
  
  res.json({ 
    isAuthenticated, 
    userId: req.session.userId 
  });
});

// Login
app.post('/api/login', authLimiter, async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    // Récupérer l'utilisateur depuis la DB
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }

    // Vérifier le mot de passe
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({ error: 'Identifiants invalides' });
    }

    // Créer la session
    req.session.userId = user.user_id;

    // Mettre à jour last_login
    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE user_id = $1',
      [user.user_id]
    );

    res.json({ 
      message: 'Connecté avec succès', 
      userId: user.user_id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Logout
app.post('/api/logout', (req, res) => {
  /* #swagger.tags = ['Auth'] */
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ error: 'Erreur lors de la déconnexion' });
    }
    res.json({ message: 'Déconnecté avec succès' });
  });
});

// Register
app.post('/api/register', authLimiter, async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const {
      email,
      password,
      first_name,
      last_name,
      desired_role,
      referral_code,
      lesson_mode,
      visio_tool,
      lesson_places,
    } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    // Validation du mot de passe
    if (password.length < 8) {
      return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 8 caractères' });
    }

    // Vérifier si l'utilisateur existe déjà
    const existing = await pool.query(
      'SELECT user_id FROM users WHERE email = $1',
      [email]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Cet email est déjà utilisé' });
    }

    // Le rôle est choisi explicitement par le client (étudiant/tuteur), un code de
    // parrainage valide est obligatoire pour un compte étudiant. Le rôle n'est jamais
    // "ADMIN" via cette route.
    let normalizedRole;
    let referredBy;
    try {
      ({ role: normalizedRole, referredBy } = await resolveRoleFromReferral(desired_role, referral_code));
    } catch (roleErr) {
      return res.status(roleErr.statusCode || 400).json({ error: roleErr.message });
    }

    const normalizedLessonMode = normalizeLessonMode(lesson_mode);
    const normalizedVisioTool = normalizeVisioTool(visio_tool);
    const normalizedLessonPlaces = normalizeTutorPlaces(lesson_places);
    const newReferralCode = await generateUniqueReferralCode();

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(password, 12);

    // Créer l'utilisateur
    const result = await pool.query(
      `INSERT INTO users
      (email, password_hash, first_name, last_name, role, lesson_mode, visio_tool, lesson_places, is_verified, created_at, referral_code, referred_by)
      VALUES ($1, $2, $3, $4, $5::user_role, $6, $7, $8, false, NOW(), $9, $10)
      RETURNING user_id, email, first_name, last_name, role, lesson_mode, visio_tool, lesson_places, created_at, referral_code`,
      [
        email,
        hashedPassword,
        first_name || null,
        last_name || null,
        normalizedRole,
        normalizedLessonMode,
        normalizedVisioTool,
        normalizedLessonPlaces,
        newReferralCode,
        referredBy,
      ]
    );

    const newUser = result.rows[0];

    // Assigner automatiquement une adresse blockchain
    try {
      await assignBlockchainAddress(newUser.user_id);
    } catch (walletError) {
      console.error('Erreur assignation wallet:', walletError);
      // Ne pas faire échouer l'inscription si l'assignation échoue
    }

    // Si ce compte étudiant a été créé via un code de parrainage, on l'ajoute
    // automatiquement au carnet de bénéficiaires du tuteur parrain.
    if (referredBy) {
      await addStudentAsBeneficiary(referredBy, newUser.user_id, `${newUser.first_name || ''} ${newUser.last_name || ''}`.trim());
    }

    res.status(201).json({
      message: 'Utilisateur créé avec succès',
      user: newUser
    });

  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// LinkedIn OAuth - démarrage du flux d'autorisation (connexion / inscription)
app.get('/api/auth/linkedin', (req, res) => {
  /* #swagger.tags = ['Auth'] */
  const state = crypto.randomBytes(16).toString('hex');
  req.session.linkedinOAuthState = state;
  delete req.session.linkedinLinkUserId;
  delete req.session.linkedinReturnTo;
  res.redirect(getLinkedInAuthorizationUrl(state));
});

// Pages autorisées comme retour après une liaison LinkedIn (évite les redirections ouvertes)
const LINKEDIN_LINK_RETURN_PATHS = ['/profile', '/create_request'];

// LinkedIn OAuth - démarrage du flux de LIAISON à un compte déjà connecté
// Réservé aux tuteurs : voir la vérification de rôle plus bas et dans le callback.
app.get('/api/auth/linkedin/link', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const userResult = await pool.query('SELECT role FROM users WHERE user_id = $1', [req.session.userId]);
    if (userResult.rows.length === 0 || userResult.rows[0].role !== 'TUTOR') {
      return res.status(403).json({ error: 'Seuls les comptes tuteur peuvent lier LinkedIn' });
    }

    const returnTo = LINKEDIN_LINK_RETURN_PATHS.includes(req.query.returnTo) ? req.query.returnTo : '/profile';

    const state = crypto.randomBytes(16).toString('hex');
    req.session.linkedinOAuthState = state;
    req.session.linkedinLinkUserId = req.session.userId;
    req.session.linkedinReturnTo = returnTo;
    res.redirect(getLinkedInAuthorizationUrl(state));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Délier son compte LinkedIn
app.delete('/api/auth/linkedin/link', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    await pool.query('UPDATE users SET linkedin_email = NULL WHERE user_id = $1', [req.session.userId]);
    res.json({ success: true, message: 'Compte LinkedIn délié' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// LinkedIn OAuth - retour depuis LinkedIn
app.get('/api/auth/linkedin/callback', async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const { code, state } = req.query;

    if (!code || !state || state !== req.session.linkedinOAuthState) {
      return res.redirect('/login?linkedin=error');
    }

    delete req.session.linkedinOAuthState;

    const accessToken = await exchangeCodeForToken(code);
    const profile = await fetchLinkedInProfile(accessToken);

    if (!profile.email) {
      return res.redirect('/login?linkedin=error');
    }

    // ── Liaison à un compte déjà connecté (tuteur) ──────────────────────
    const linkUserId = req.session.linkedinLinkUserId;
    if (linkUserId) {
      const returnTo = req.session.linkedinReturnTo || '/profile';
      delete req.session.linkedinLinkUserId;
      delete req.session.linkedinReturnTo;

      const conflict = await pool.query(
        'SELECT user_id FROM users WHERE (email = $1 OR linkedin_email = $1) AND user_id != $2',
        [profile.email, linkUserId]
      );
      if (conflict.rows.length > 0) {
        return res.redirect(`${returnTo}?linkedin=conflict`);
      }

      await pool.query('UPDATE users SET linkedin_email = $1 WHERE user_id = $2', [profile.email, linkUserId]);
      return res.redirect(`${returnTo}?linkedin=linked`);
    }

    // ── Connexion / inscription ──────────────────────────────────────────
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR linkedin_email = $1',
      [profile.email]
    );
    const existingUser = result.rows[0];

    if (existingUser) {
      req.session.userId = existingUser.user_id;
      await pool.query(
        'UPDATE users SET last_login = NOW() WHERE user_id = $1',
        [existingUser.user_id]
      );
      return res.redirect('/login?linkedin=connected');
    }

    // Compte inexistant : il manque le rôle (étudiant/tuteur), pas fourni par LinkedIn
    req.session.pendingLinkedInProfile = {
      email: profile.email,
      emailVerified: profile.emailVerified,
      firstName: profile.firstName,
      lastName: profile.lastName,
    };
    res.redirect('/login?linkedin=complete-profile');

  } catch (err) {
    console.error('LinkedIn OAuth callback error:', err);
    res.redirect('/login?linkedin=error');
  }
});

// LinkedIn OAuth - finalisation de la création de compte (rôle choisi par l'utilisateur)
app.post('/api/auth/linkedin/complete-profile', authLimiter, async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const pendingProfile = req.session.pendingLinkedInProfile;

    if (!pendingProfile) {
      return res.status(400).json({ error: 'Aucune connexion LinkedIn en attente' });
    }

    const { desired_role, referral_code, lesson_mode, visio_tool, lesson_places } = req.body;

    // Le rôle est choisi explicitement par le client (étudiant/tuteur), un code de
    // parrainage valide est obligatoire pour un compte étudiant.
    let normalizedRole;
    let referredBy;
    try {
      ({ role: normalizedRole, referredBy } = await resolveRoleFromReferral(desired_role, referral_code));
    } catch (roleErr) {
      return res.status(roleErr.statusCode || 400).json({ error: roleErr.message });
    }

    const normalizedLessonMode = normalizeLessonMode(lesson_mode);
    const normalizedVisioTool = normalizeVisioTool(visio_tool);
    const normalizedLessonPlaces = normalizeTutorPlaces(lesson_places);
    const newReferralCode = await generateUniqueReferralCode();

    // Vérifier qu'un compte n'a pas été créé entre-temps avec cet email
    const existing = await pool.query(
      'SELECT user_id FROM users WHERE email = $1',
      [pendingProfile.email]
    );
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Cet email est déjà utilisé' });
    }

    // Mot de passe aléatoire : le compte est créé via LinkedIn, jamais utilisé pour se connecter par mot de passe
    const randomPassword = crypto.randomBytes(32).toString('hex');
    const hashedPassword = await bcrypt.hash(randomPassword, 12);

    const result = await pool.query(
      `INSERT INTO users
      (email, password_hash, first_name, last_name, role, lesson_mode, visio_tool, lesson_places, is_verified, created_at, referral_code, referred_by)
      VALUES ($1, $2, $3, $4, $5::user_role, $6, $7, $8, $9, NOW(), $10, $11)
      RETURNING user_id, email, first_name, last_name, role, lesson_mode, visio_tool, lesson_places, created_at, referral_code`,
      [
        pendingProfile.email,
        hashedPassword,
        pendingProfile.firstName,
        pendingProfile.lastName,
        normalizedRole,
        normalizedLessonMode,
        normalizedVisioTool,
        normalizedLessonPlaces,
        pendingProfile.emailVerified,
        newReferralCode,
        referredBy,
      ]
    );

    const newUser = result.rows[0];

    try {
      await assignBlockchainAddress(newUser.user_id);
    } catch (walletError) {
      console.error('Erreur assignation wallet:', walletError);
    }

    if (referredBy) {
      await addStudentAsBeneficiary(referredBy, newUser.user_id, `${newUser.first_name || ''} ${newUser.last_name || ''}`.trim());
    }

    delete req.session.pendingLinkedInProfile;
    req.session.userId = newUser.user_id;

    res.status(201).json({
      message: 'Compte créé avec succès',
      user: newUser
    });

  } catch (err) {
    console.error('LinkedIn complete-profile error:', err);
    res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// Profil utilisateur
app.get('/api/profile', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    // Récupérer les infos utilisateur
    const userResult = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, lesson_mode, visio_tool, lesson_places,
              is_verified, created_at, last_login, referral_code, linkedin_email, avatar_url
       FROM users WHERE user_id = $1`,
      [req.session.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const user = userResult.rows[0];
    const { balance, blockchainAddress, stats } = await getWalletBalanceAndStats(req.session.userId);

    res.json({
      ...user,
      balance,
      blockchainAddress,
      stats
    });

  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ error: 'Erreur lors de la récupération du profil' });
  }
});

app.put('/api/profile/lesson-locations', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const { lesson_mode, visio_tool, lesson_places } = req.body;

    const userRoleResult = await pool.query(
      'SELECT role FROM users WHERE user_id = $1',
      [req.session.userId]
    );

    if (userRoleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const role = userRoleResult.rows[0].role;
    if (role !== 'TUTOR') {
      return res.status(403).json({ error: 'Seuls les tuteurs peuvent modifier leurs lieux de cours' });
    }

    const normalizedLessonMode = normalizeLessonMode(lesson_mode);
    const normalizedVisioTool = normalizeVisioTool(visio_tool);
    const normalizedLessonPlaces = normalizeTutorPlaces(lesson_places);

    const result = await pool.query(
      `UPDATE users
       SET lesson_mode = $1,
           visio_tool = $2,
           lesson_places = $3
       WHERE user_id = $4
       RETURNING lesson_mode, visio_tool, lesson_places`,
      [normalizedLessonMode, normalizedVisioTool, normalizedLessonPlaces, req.session.userId]
    );

    res.json({ success: true, ...result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST bascule permanente d'un compte étudiant vers un compte tuteur
app.post('/api/profile/become-tutor', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const userResult = await pool.query('SELECT role FROM users WHERE user_id = $1', [req.session.userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    if (userResult.rows[0].role !== 'STUDENT') {
      return res.status(403).json({ error: 'Seul un compte étudiant peut basculer vers un compte tuteur' });
    }

    const { lesson_mode, visio_tool, lesson_places } = req.body;
    const normalizedLessonMode = normalizeLessonMode(lesson_mode);
    const normalizedVisioTool = normalizeVisioTool(visio_tool);
    const normalizedLessonPlaces = normalizeTutorPlaces(lesson_places);

    const result = await pool.query(
      `UPDATE users
       SET role = 'TUTOR', lesson_mode = $1, visio_tool = $2, lesson_places = $3
       WHERE user_id = $4
       RETURNING user_id, role, lesson_mode, visio_tool, lesson_places`,
      [normalizedLessonMode, normalizedVisioTool, normalizedLessonPlaces, req.session.userId]
    );

    res.json({ success: true, ...result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST changer sa photo de profil
app.post('/api/profile/avatar', authGuard({ mustBeLogged: true }), uploadAvatar.single('avatar'), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucune image fournie' });
    }

    const avatarUrl = `/api/uploads/avatars/${req.file.filename}`;

    const oldResult = await pool.query('SELECT avatar_url FROM users WHERE user_id = $1', [req.session.userId]);
    const oldAvatarUrl = oldResult.rows[0]?.avatar_url;

    await pool.query('UPDATE users SET avatar_url = $1 WHERE user_id = $2', [avatarUrl, req.session.userId]);

    deleteAvatarFile(oldAvatarUrl);

    res.json({ success: true, avatar_url: avatarUrl });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE retirer sa photo de profil
app.delete('/api/profile/avatar', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const oldResult = await pool.query('SELECT avatar_url FROM users WHERE user_id = $1', [req.session.userId]);
    const oldAvatarUrl = oldResult.rows[0]?.avatar_url;

    await pool.query('UPDATE users SET avatar_url = NULL WHERE user_id = $1', [req.session.userId]);

    deleteAvatarFile(oldAvatarUrl);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST changement de mot de passe
app.post('/api/reset-password', authLimiter, authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Mot de passe actuel et nouveau mot de passe requis' });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ error: 'Le nouveau mot de passe doit contenir au moins 8 caractères' });
    }

    const userResult = await pool.query(
      'SELECT password_hash FROM users WHERE user_id = $1',
      [req.session.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const validPassword = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Mot de passe actuel incorrect' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await pool.query(
      'UPDATE users SET password_hash = $1 WHERE user_id = $2',
      [hashedPassword, req.session.userId]
    );

    res.json({ success: true, message: 'Mot de passe mis à jour avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE account (suppression complète du compte)
app.delete('/api/account', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  const client = await pool.connect();
  
  try {
    const userId = req.session.userId;
    
    console.log(`🗑️ Début de la suppression du compte: ${userId}`);
    
    await client.query('BEGIN');

    // 1. Récupérer l'email de l'utilisateur pour Qdrant
    const userResult = await client.query(
      'SELECT email FROM users WHERE user_id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const userEmail = userResult.rows[0].email;

    // Détacher les comptes que cet utilisateur a parrainés : on efface juste la référence
    // (referred_by), on ne supprime surtout pas ces comptes en cascade.
    await client.query(
      'UPDATE users SET referred_by = NULL WHERE referred_by = $1',
      [userId]
    );

    // 2. Supprimer les données Qdrant associées à l'utilisateur
    try {
      // Rechercher tous les points Qdrant créés par cet utilisateur
      const qdrantSearchResponse = await fetch(`${process.env.QDRANT_URL || 'http://qdrant:6333'}/collections/tutoring_listings/points/scroll`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          filter: {
            must: [
              {
                key: "tutor_email",
                match: { value: userEmail }
              }
            ]
          },
          limit: 100
        })
      });

      if (qdrantSearchResponse.ok) {
        const qdrantData = await qdrantSearchResponse.json();
        const pointIds = qdrantData.result?.points?.map(p => p.id) || [];

        // Supprimer tous les points trouvés
        if (pointIds.length > 0) {
          await fetch(`${process.env.QDRANT_URL || 'http://qdrant:6333'}/collections/tutoring_listings/points/delete`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              points: pointIds
            })
          });
          console.log(`✅ ${pointIds.length} annonces Qdrant supprimées`);
        }
      }
    } catch (qdrantError) {
      console.warn('⚠️ Erreur lors de la suppression Qdrant (non bloquant):', qdrantError.message);
    }

    // 3. Supprimer les données PostgreSQL dans l'ordre (respect des foreign keys)

    // Supprimer les réservations faites par l'utilisateur (en tant qu'étudiant).
    // Pas de ON DELETE CASCADE sur bookings.user_id : sans cette étape, la suppression
    // d'un compte étudiant ayant déjà réservé un cours échoue (violation de contrainte).
    await client.query(
      'DELETE FROM bookings WHERE user_id = $1',
      [userId]
    );
    console.log('✅ Réservations supprimées');

    // Récupérer les wallet_id de l'utilisateur
    const walletResult = await client.query(
      'SELECT wallet_id FROM wallets WHERE user_id = $1',
      [userId]
    );
    const walletIds = walletResult.rows.map(row => row.wallet_id);

    // Supprimer les transactions liées aux wallets
    if (walletIds.length > 0) {
      await client.query(
        'DELETE FROM transactions WHERE from_wallet = ANY($1) OR to_wallet = ANY($1)',
        [walletIds]
      );
      console.log('✅ Transactions supprimées');
    }

    // Supprimer les messages où l'utilisateur est impliqué
    await client.query(
      'DELETE FROM messages WHERE sender_id = $1',
      [userId]
    );
    console.log('✅ Messages supprimés');

    // Supprimer les conversations où l'utilisateur est impliqué
    await client.query(
      'DELETE FROM conversations WHERE user1_id = $1 OR user2_id = $1',
      [userId]
    );
    console.log('✅ Conversations supprimées');

    // Supprimer les participations aux services
    await client.query(
      'DELETE FROM service_participations WHERE user_id = $1 OR validated_by = $1',
      [userId]
    );
    console.log('✅ Participations aux services supprimées');

    // Supprimer les services créés par l'utilisateur
    await client.query(
      'DELETE FROM services WHERE created_by = $1',
      [userId]
    );
    console.log('✅ Services supprimés');

    // Supprimer les wallets
    await client.query(
      'DELETE FROM wallets WHERE user_id = $1',
      [userId]
    );
    console.log('✅ Wallets supprimés');

    // Supprimer les actions admin
    await client.query(
      'DELETE FROM admin_actions WHERE admin_id = $1 OR target_id = $1',
      [userId]
    );
    console.log('✅ Actions admin supprimées');

    // Supprimer les API keys (owner est l'email)
    await client.query(
      'DELETE FROM api_keys WHERE owner = $1',
      [userEmail]
    );
    console.log('✅ API keys supprimées');

    // Enfin, supprimer l'utilisateur
    await client.query(
      'DELETE FROM users WHERE user_id = $1',
      [userId]
    );
    console.log('✅ Utilisateur supprimé');

    await client.query('COMMIT');
    
    console.log(`✅ Compte ${userEmail} supprimé avec succès`);

    // Détruire la session (on répond une fois que c'est réellement fait : sinon un
    // appel /api/check-auth juste après pourrait encore lire l'ancienne session).
    req.session.destroy((err) => {
      if (err) {
        console.error('Erreur destruction session:', err);
      }
      res.json({ message: 'Compte supprimé avec succès' });
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur lors de la suppression du compte:', err);
    res.status(500).json({ error: 'Erreur lors de la suppression du compte' });
  } finally {
    client.release();
  }
});

/* ========================================
   ROUTES API - USERS (CRUD)
   ======================================== */

// GET tous les utilisateurs (réservé aux administrateurs)
app.get('/api/users', requireAdmin(), async (req, res) => {
  /* #swagger.tags = ['Users'] */
  try {
    const result = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, is_verified, created_at, last_login
       FROM users ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET un utilisateur par ID (réservé aux administrateurs)
app.get('/api/users/:user_id', requireAdmin(), async (req, res) => {
  /* #swagger.tags = ['Users'] */
  try {
    const result = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, is_verified, created_at, last_login
       FROM users WHERE user_id = $1`,
      [req.params.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE utilisateur (réservé aux administrateurs — les utilisateurs modifient leur propre
// profil via PUT /api/profile/lesson-locations, qui ne permet pas de changer le rôle)
app.put('/api/users/:user_id', requireAdmin(), async (req, res) => {
  /* #swagger.tags = ['Users'] */
  try {
    const { first_name, last_name, role } = req.body;

    if (role !== undefined && !['STUDENT', 'TUTOR', 'ADMIN'].includes(String(role).toUpperCase())) {
      return res.status(400).json({ error: 'Rôle invalide' });
    }

    const result = await pool.query(
      `UPDATE users
       SET first_name = COALESCE($1, first_name),
           last_name = COALESCE($2, last_name),
           role = COALESCE($3, role)
       WHERE user_id = $4
       RETURNING user_id, email, first_name, last_name, role, is_verified`,
      [first_name, last_name, role ? String(role).toUpperCase() : null, req.params.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE utilisateur (réservé aux administrateurs — un utilisateur supprime son propre
// compte via DELETE /api/account)
app.delete('/api/users/:user_id', requireAdmin(), async (req, res) => {
  /* #swagger.tags = ['Users'] */
  try {
    const result = await pool.query(
      'DELETE FROM users WHERE user_id = $1 RETURNING user_id',
      [req.params.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({ message: 'Utilisateur supprimé avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - DISPONIBILITÉS TUTEURS
   ======================================== */

// GET créneaux disponibles
// Filtres optionnels: ?listing_id=xxx  ou  ?tutor_user_id=xxx
app.get('/api/availability', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const { listing_id, tutor_user_id } = req.query;

    let query = `
      SELECT ta.slot_id, ta.tutor_user_id, ta.listing_id,
             ta.start_time, ta.end_time, ta.is_booked, ta.created_at,
             u.first_name AS tutor_first_name, u.last_name AS tutor_last_name, u.email AS tutor_email
      FROM tutor_availability ta
      JOIN users u ON u.user_id = ta.tutor_user_id
      WHERE ta.is_booked = FALSE AND ta.start_time > NOW()
    `;
    const params = [];

    if (listing_id && listing_id !== 'undefined' && listing_id !== 'null') {
      params.push(listing_id);
      query += ` AND ta.listing_id = $${params.length}`;
    }

    if (tutor_user_id && tutor_user_id !== 'undefined' && tutor_user_id !== 'null') {
      params.push(tutor_user_id);
      query += ` AND ta.tutor_user_id = $${params.length}`;
    }

    query += ' ORDER BY ta.start_time ASC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET tous les créneaux du tuteur connecté (y compris déjà réservés)
app.get('/api/availability/mine', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const result = await pool.query(
      `SELECT slot_id, tutor_user_id, listing_id,
              start_time, end_time, is_booked, created_at
       FROM tutor_availability
       WHERE tutor_user_id = $1
       ORDER BY start_time ASC`,
      [req.session.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Helper function: validate time is on round/half-hour boundary (XX:00 or XX:30)
function isValidTimeSlot(dateString) {
  const date = new Date(dateString);
  const minutes = date.getMinutes();
  return minutes === 0 || minutes === 30;
}

// Helper function: generate 1-hour slots from a time range
function generateOneHourSlots(startTime, endTime) {
  const slots = [];
  let current = new Date(startTime);
  
  while (current < new Date(endTime)) {
    const slotEnd = new Date(current);
    slotEnd.setHours(slotEnd.getHours() + 1);
    
    // Don't go past the requested end time
    if (slotEnd > new Date(endTime)) {
      slotEnd.setTime(new Date(endTime).getTime());
    }
    
    slots.push({
      start: new Date(current),
      end: slotEnd
    });
    
    current = slotEnd;
  }
  
  return slots;
}

// POST créer des créneaux (tuteur uniquement)
// Automatically splits long time ranges into 1-hour slots
app.post('/api/availability', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  const client = await pool.connect();
  try {
    // Vérifier que l'utilisateur est bien un TUTOR
    const userResult = await client.query(
      'SELECT role FROM users WHERE user_id = $1',
      [req.session.userId]
    );
    if (userResult.rows.length === 0 || userResult.rows[0].role !== 'TUTOR') {
      return res.status(403).json({ error: 'Seuls les tuteurs peuvent créer des créneaux' });
    }

    // Accepter soit un seul créneau soit un tableau
    let inputSlots = req.body;
    if (!Array.isArray(inputSlots)) {
      inputSlots = [inputSlots];
    }

    const created = [];
    
    await client.query('BEGIN');

    for (const inputSlot of inputSlots) {
      const { listing_id, start_time, end_time } = inputSlot;
      
      if (!start_time || !end_time) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'start_time et end_time sont requis' });
      }

      // Validate that times are on round/half-hour boundaries
      if (!isValidTimeSlot(start_time)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ 
          error: 'La date de début doit être à XX:00 ou XX:30' 
        });
      }
      if (!isValidTimeSlot(end_time)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ 
          error: 'La date de fin doit être à XX:00 ou XX:30' 
        });
      }

      const startDate = new Date(start_time);
      const endDate = new Date(end_time);

      if (endDate <= startDate) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'end_time doit être après start_time' });
      }

      // Generate 1-hour slots
      const oneHourSlots = generateOneHourSlots(startDate, endDate);

      if (oneHourSlots.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'L\'intervalle doit couvrir au moins 1 heure' });
      }

      // Check for overlaps with THIS TUTOR's existing slots (booked or not)
      for (const hourSlot of oneHourSlots) {
        const overlap = await client.query(
          `SELECT slot_id FROM tutor_availability
           WHERE tutor_user_id = $1
             AND tsrange(start_time, end_time, '[]') && tsrange($2::timestamp, $3::timestamp, '[]')`,
          [req.session.userId, hourSlot.start.toISOString(), hourSlot.end.toISOString()]
        );
        
        if (overlap.rows.length > 0) {
          await client.query('ROLLBACK');
          return res.status(409).json({ 
            error: `Créneau en conflit avec une disponibilité existante (${hourSlot.start.toISOString()})` 
          });
        }
      }

      // Insert all 1-hour slots for this input range
      for (const hourSlot of oneHourSlots) {
        const result = await client.query(
          `INSERT INTO tutor_availability (tutor_user_id, listing_id, start_time, end_time)
           VALUES ($1, $2, $3, $4)
           RETURNING *`,
          [req.session.userId, listing_id || null, hourSlot.start.toISOString(), hourSlot.end.toISOString()]
        );
        created.push(result.rows[0]);
      }
    }

    await client.query('COMMIT');
    res.status(201).json(created);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error in POST /api/availability:', err);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// DELETE supprimer un créneau (tuteur propriétaire uniquement)
app.delete('/api/availability/:slot_id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    // Vérifier que le créneau appartient à ce tuteur
    const slotResult = await pool.query(
      'SELECT * FROM tutor_availability WHERE slot_id = $1',
      [req.params.slot_id]
    );
    if (slotResult.rows.length === 0) {
      return res.status(404).json({ error: 'Créneau non trouvé' });
    }
    const slot = slotResult.rows[0];
    if (slot.tutor_user_id !== req.session.userId) {
      return res.status(403).json({ error: 'Non autorisé' });
    }
    if (slot.is_booked) {
      return res.status(409).json({ error: 'Ce créneau est déjà réservé et ne peut pas être supprimé' });
    }

    await pool.query('DELETE FROM tutor_availability WHERE slot_id = $1', [req.params.slot_id]);
    res.json({ message: 'Créneau supprimé avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - BOOKINGS (RÉSERVATIONS)
   ======================================== */

// Charge une réservation et vérifie que l'appelant est soit l'étudiant qui a réservé,
// soit le tuteur du créneau concerné. Lève une erreur avec statusCode sinon.
async function assertBookingAccess(bookingId, sessionUserId) {
  const result = await pool.query(
    `SELECT b.*, ta.tutor_user_id
     FROM bookings b
     LEFT JOIN tutor_availability ta ON b.slot_id = ta.slot_id
     WHERE b.booking_id = $1`,
    [bookingId]
  );

  if (result.rows.length === 0) {
    const err = new Error('Réservation non trouvée');
    err.statusCode = 404;
    throw err;
  }

  const booking = result.rows[0];
  const isOwner = booking.user_id === sessionUserId;
  const isTutor = booking.tutor_user_id === sessionUserId;

  if (!isOwner && !isTutor) {
    const err = new Error('Non autorisé');
    err.statusCode = 403;
    throw err;
  }

  return booking;
}

// Libère le créneau associé à une réservation (utilisé à l'annulation/suppression)
async function releaseBookingSlot(booking, client = pool) {
  if (booking.slot_id) {
    await client.query('UPDATE tutor_availability SET is_booked = FALSE WHERE slot_id = $1', [booking.slot_id]);
  }
}

// GET les réservations de l'utilisateur connecté (élève et/ou tuteur)
app.get('/api/bookings', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    // Le filtre est toujours celui de l'utilisateur connecté : impossible de consulter
    // les réservations d'un autre utilisateur en changeant le paramètre user_id.
    const userId = req.session.userId;

    const query = `
      SELECT b.booking_id, b.user_id, b.listing_id, b.title, b.description, b.subject,
             b.start_time, b.end_time, b.status, b.tutor_name, b.price, b.notes,
             b.created_at, b.updated_at,
             CONCAT(u.first_name, ' ', u.last_name) AS student_name
      FROM bookings b
      LEFT JOIN tutor_availability ta ON b.slot_id = ta.slot_id
      LEFT JOIN users u ON u.user_id = b.user_id
      WHERE b.user_id = $1 OR ta.tutor_user_id = $1
      ORDER BY b.start_time ASC
    `;
    const result = await pool.query(query, [userId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET notifications pour le tuteur connecté
app.get('/api/tutor/notifications', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const userId = req.session.userId;

    const result = await pool.query(
      `SELECT b.*
       FROM bookings b
       LEFT JOIN tutor_availability ta ON b.slot_id = ta.slot_id
       WHERE b.is_notified_tutor = FALSE
         AND (ta.tutor_user_id = $1 OR b.tutor_email = (SELECT email FROM users WHERE user_id = $1))`,
      [userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// MARQUER notifications comme lues (uniquement les réservations dont on est le tuteur)
app.put('/api/tutor/notifications/mark-read', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const { booking_ids } = req.body;
    if (!booking_ids || !Array.isArray(booking_ids) || booking_ids.length === 0) {
      return res.status(400).json({ error: 'Tableau booking_ids requis' });
    }

    const userId = req.session.userId;
    await pool.query(
      `UPDATE bookings b
       SET is_notified_tutor = TRUE
       FROM tutor_availability ta
       WHERE b.slot_id = ta.slot_id
         AND b.booking_id = ANY($1::uuid[])
         AND ta.tutor_user_id = $2`,
      [booking_ids, userId]
    );

    res.json({ message: 'Notifications marquées comme lues' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET une réservation par ID (élève ou tuteur concerné uniquement)
app.get('/api/bookings/:booking_id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const booking = await assertBookingAccess(req.params.booking_id, req.session.userId);
    res.json(booking);
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// CREATE nouvelle réservation
app.post('/api/bookings', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  const client = await pool.connect();
  try {
    const user_id = req.session.userId;
    if (!user_id) {
      return res.status(401).json({ error: 'Non authentifié' });
    }

    const {
      slot_ids,           // NEW: array of slot UUIDs chosen by the student
      listing_id, title, description, subject,
      start_time, end_time, tutor_name, tutor_email, price, notes
    } = req.body;

    await client.query('BEGIN');

    // ── Slot-based booking ──────────────────────────────────────────
    if (slot_ids && Array.isArray(slot_ids) && slot_ids.length > 0) {
      const created = [];

      for (const slot_id of slot_ids) {
        // Lock the row to prevent concurrent bookings
        const slotResult = await client.query(
          'SELECT * FROM tutor_availability WHERE slot_id = $1 FOR UPDATE',
          [slot_id]
        );
        if (slotResult.rows.length === 0) {
          await client.query('ROLLBACK');
          return res.status(404).json({ error: `Créneau introuvable: ${slot_id}` });
        }
        const slot = slotResult.rows[0];
        if (slot.is_booked) {
          await client.query('ROLLBACK');
          return res.status(409).json({ error: `Ce créneau est déjà réservé: ${slot_id}` });
        }

        // Compute per-slot price (hours × price/h)
        const durationH = (new Date(slot.end_time) - new Date(slot.start_time)) / (1000 * 60 * 60);
        const slotPrice = price != null ? durationH * parseFloat(price) : null;

        const result = await client.query(
          `INSERT INTO bookings
           (user_id, listing_id, slot_id, title, description, subject,
            start_time, end_time, status, tutor_name, tutor_email, price, notes)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', $9, $10, $11, $12)
           RETURNING *`,
          [user_id, slot.listing_id || listing_id, slot_id,
           title || '', description, subject,
           slot.start_time, slot.end_time,
           tutor_name, tutor_email, slotPrice, notes]
        );

        // Mark the slot as booked
        await client.query(
          'UPDATE tutor_availability SET is_booked = TRUE WHERE slot_id = $1',
          [slot_id]
        );

        created.push(result.rows[0]);
      }

      await client.query('COMMIT');
      return res.status(201).json(created);
    }

    // ── Manual booking (legacy) ─────────────────────────────────────
    if (!title || !start_time || !end_time) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Champs requis manquants (title, start_time, end_time)' });
    }

    const result = await client.query(
      `INSERT INTO bookings
       (user_id, listing_id, title, description, subject, start_time, end_time,
        status, tutor_name, tutor_email, price, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', $8, $9, $10, $11)
       RETURNING *`,
      [user_id, listing_id, title, description, subject, start_time, end_time,
       tutor_name, tutor_email, price, notes]
    );

    await client.query('COMMIT');
    res.status(201).json(result.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// UPDATE réservation (élève ou tuteur concerné uniquement)
app.put('/api/bookings/:booking_id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const existing = await assertBookingAccess(req.params.booking_id, req.session.userId);

    const {
      title, description, subject, start_time, end_time,
      status, tutor_name, price, notes
    } = req.body;

    if (status && !['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }

    const result = await pool.query(
      `UPDATE bookings
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           subject = COALESCE($3, subject),
           start_time = COALESCE($4, start_time),
           end_time = COALESCE($5, end_time),
           status = COALESCE($6, status),
           tutor_name = COALESCE($7, tutor_name),
           price = COALESCE($8, price),
           notes = COALESCE($9, notes),
           updated_at = NOW()
       WHERE booking_id = $10
       RETURNING *`,
      [title, description, subject, start_time, end_time, status,
       tutor_name, price, notes, req.params.booking_id]
    );

    const updated = result.rows[0];

    // Si la réservation vient d'être annulée, on libère le créneau associé
    if (status === 'cancelled' && existing.status !== 'cancelled') {
      await releaseBookingSlot(updated);
    }

    res.json(updated);
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// UPDATE statut réservation (élève ou tuteur concerné uniquement)
app.patch('/api/bookings/:booking_id/status', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const { status } = req.body;

    if (!['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }

    const existing = await assertBookingAccess(req.params.booking_id, req.session.userId);

    const result = await pool.query(
      `UPDATE bookings
       SET status = $1, updated_at = NOW()
       WHERE booking_id = $2
       RETURNING *`,
      [status, req.params.booking_id]
    );

    const updated = result.rows[0];

    // Bug connu corrigé : un créneau annulé restait marqué "réservé" et bloquait
    // ce horaire pour toujours. On le libère dès que le statut passe à "cancelled".
    if (status === 'cancelled' && existing.status !== 'cancelled') {
      await releaseBookingSlot(updated);
    }

    res.json(updated);
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// DELETE réservation (élève ou tuteur concerné uniquement)
app.delete('/api/bookings/:booking_id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const existing = await assertBookingAccess(req.params.booking_id, req.session.userId);

    // On libère systématiquement le créneau : une réservation supprimée ne doit
    // jamais laisser le créneau bloqué comme "réservé".
    await releaseBookingSlot(existing);

    await pool.query('DELETE FROM bookings WHERE booking_id = $1', [req.params.booking_id]);

    res.json({ message: 'Réservation supprimée avec succès' });
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - BLOCKCHAIN
   ======================================== */

// GET tous les comptes blockchain (réservé aux administrateurs : expose toutes les adresses/soldes)
app.get('/api/blockchain/accounts', requireAdmin(), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const accounts = await getAllAccounts();
    res.json({ success: true, accounts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET balance d'un compte
app.get('/api/blockchain/balance/:address', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const balance = await getBalance(req.params.address);
    res.json({ success: true, ...balance });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET détails d'une transaction
app.get('/api/blockchain/transaction/:txHash', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const details = await getTransactionDetails(req.params.txHash);
    res.json({ success: true, ...details });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST transaction blockchain — envoie des CCT DEPUIS le wallet de l'utilisateur connecté.
// L'adresse source n'est JAMAIS fournie par le client : elle est toujours résolue depuis
// la session, pour empêcher quiconque de vider le wallet d'un autre utilisateur.
app.post('/api/blockchain/transaction', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const { toAddress, amount } = req.body;

    if (!toAddress || !amount || Number(amount) <= 0) {
      return res.status(400).json({ error: 'Adresse destinataire et montant (positif) requis' });
    }

    const senderWallet = await getSenderWallet(req.session.userId);

    if (!senderWallet) {
      return res.status(400).json({ error: 'Aucun wallet associé à ce compte' });
    }

    const { walletId: fromWalletId, address: fromAddress, privateKey } = senderWallet;

    if (fromAddress.toLowerCase() === String(toAddress).toLowerCase()) {
      return res.status(400).json({ error: 'Impossible de vous envoyer des CCT à vous-même' });
    }

    const currentBalance = await getBalance(fromAddress);
    if (parseFloat(currentBalance.balanceEth) < Number(amount)) {
      return res.status(400).json({ error: 'Solde insuffisant' });
    }

    const toWalletId = await findWalletIdByAddress(toAddress);

    try {
      const result = await sendTransaction(fromAddress, toAddress, amount, privateKey);

      await pool.query(
        `INSERT INTO transactions (tx_hash, from_wallet, to_wallet, amount, status, type)
         VALUES ($1, $2, $3, $4, 'CONFIRMED', 'TRANSFER')`,
        [result.transactionHash, fromWalletId, toWalletId, amount]
      );

      res.json({ success: true, ...result });
    } catch (txError) {
      await pool.query(
        `INSERT INTO transactions (tx_hash, from_wallet, to_wallet, amount, status, type)
         VALUES (NULL, $1, $2, $3, 'FAILED', 'TRANSFER')`,
        [fromWalletId, toWalletId, amount]
      );
      throw txError;
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - BÉNÉFICIAIRES (carnet d'adresses pour les transferts)
   ======================================== */

// GET mes bénéficiaires
app.get('/api/beneficiaries', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const result = await pool.query(
      `SELECT beneficiary_id, label, address, created_at
       FROM beneficiaries WHERE owner_user_id = $1 ORDER BY created_at DESC`,
      [req.session.userId]
    );
    res.json({ success: true, beneficiaries: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST ajouter un bénéficiaire
app.post('/api/beneficiaries', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const { label, address } = req.body;

    if (!label || !address || !label.trim() || !address.trim()) {
      return res.status(400).json({ error: 'Nom et adresse requis' });
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(address.trim())) {
      return res.status(400).json({ error: 'Adresse blockchain invalide (format 0x...)' });
    }

    const result = await pool.query(
      `INSERT INTO beneficiaries (owner_user_id, label, address)
       VALUES ($1, $2, $3)
       RETURNING beneficiary_id, label, address, created_at`,
      [req.session.userId, label.trim(), address.trim()]
    );

    res.status(201).json({ success: true, beneficiary: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE un bénéficiaire (propriétaire uniquement)
app.delete('/api/beneficiaries/:id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const result = await pool.query(
      'DELETE FROM beneficiaries WHERE beneficiary_id = $1 AND owner_user_id = $2 RETURNING beneficiary_id',
      [req.params.id, req.session.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Bénéficiaire non trouvé' });
    }

    res.json({ success: true, message: 'Bénéficiaire supprimé' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - MESSAGERIE (conversations privées 1-à-1)
   ======================================== */

// Vérifie que l'utilisateur connecté fait bien partie de la conversation, et renvoie
// l'id de l'autre participant. Lève une erreur avec statusCode sinon (404/403).
async function assertConversationAccess(conversationId, sessionUserId) {
  const result = await pool.query(
    'SELECT conversation_id, user1_id, user2_id FROM conversations WHERE conversation_id = $1',
    [conversationId]
  );
  if (result.rows.length === 0) {
    const err = new Error('Conversation non trouvée');
    err.statusCode = 404;
    throw err;
  }
  const conversation = result.rows[0];
  if (conversation.user1_id !== sessionUserId && conversation.user2_id !== sessionUserId) {
    const err = new Error('Non autorisé');
    err.statusCode = 403;
    throw err;
  }
  const otherUserId = conversation.user1_id === sessionUserId ? conversation.user2_id : conversation.user1_id;
  return { conversation, otherUserId };
}

// GET mes conversations, triées par dernier message décroissant, avec pour chacune
// l'autre participant, un aperçu du dernier message et le nombre de non-lus.
app.get('/api/conversations', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Messages'] */
  try {
    const userId = req.session.userId;

    const result = await pool.query(
      `SELECT
         c.conversation_id,
         ou.user_id AS other_user_id,
         ou.first_name AS other_first_name,
         ou.last_name AS other_last_name,
         ou.avatar_url AS other_avatar_url,
         ou.role AS other_role,
         lm.content AS last_message_content,
         lm.created_at AS last_message_at,
         lm.sender_id AS last_message_sender_id,
         COALESCE(unread.count, 0)::int AS unread_count
       FROM conversations c
       JOIN users ou ON ou.user_id = (CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END)
       LEFT JOIN LATERAL (
         SELECT content, created_at, sender_id
         FROM messages m
         WHERE m.conversation_id = c.conversation_id
         ORDER BY m.created_at DESC
         LIMIT 1
       ) lm ON true
       LEFT JOIN LATERAL (
         SELECT COUNT(*)::int AS count
         FROM messages m
         WHERE m.conversation_id = c.conversation_id AND m.receiver_id = $1 AND m.is_read = FALSE
       ) unread ON true
       WHERE c.user1_id = $1 OR c.user2_id = $1
       ORDER BY COALESCE(lm.created_at, c.created_at) DESC`,
      [userId]
    );

    const conversations = result.rows.map((row) => ({
      conversationId: row.conversation_id,
      otherUser: {
        userId: row.other_user_id,
        firstName: row.other_first_name,
        lastName: row.other_last_name,
        avatarUrl: row.other_avatar_url,
        role: row.other_role,
      },
      lastMessage: row.last_message_content
        ? { content: row.last_message_content, createdAt: row.last_message_at, senderId: row.last_message_sender_id }
        : null,
      unreadCount: row.unread_count,
    }));

    res.json({ success: true, conversations });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST récupère la conversation existante avec cette personne, ou la crée.
app.post('/api/conversations', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Messages'] */
  try {
    const userId = req.session.userId;
    const { other_user_id } = req.body;

    if (!other_user_id) {
      return res.status(400).json({ error: 'other_user_id requis' });
    }
    if (other_user_id === userId) {
      return res.status(400).json({ error: 'Impossible de démarrer une conversation avec vous-même' });
    }

    const otherUser = await pool.query('SELECT user_id FROM users WHERE user_id = $1', [other_user_id]);
    if (otherUser.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur introuvable' });
    }

    // Ordre canonique (le plus petit UUID en user1_id) : la contrainte unique_dm(user1_id,
    // user2_id) ne protège pas contre deux lignes pour la même paire selon qui initie la
    // conversation en premier, sans cette normalisation.
    const [user1Id, user2Id] = [userId, other_user_id].sort();

    const existing = await pool.query(
      'SELECT conversation_id FROM conversations WHERE user1_id = $1 AND user2_id = $2',
      [user1Id, user2Id]
    );

    let conversationId;
    if (existing.rows.length > 0) {
      conversationId = existing.rows[0].conversation_id;
    } else {
      const created = await pool.query(
        'INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING conversation_id',
        [user1Id, user2Id]
      );
      conversationId = created.rows[0].conversation_id;
    }

    res.status(201).json({ success: true, conversationId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET historique des messages d'une conversation (paginé, plus récents en dernier).
app.get('/api/conversations/:id/messages', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Messages'] */
  try {
    await assertConversationAccess(req.params.id, req.session.userId);

    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const before = req.query.before ? Number(req.query.before) : null;

    const params = [req.params.id];
    let query = 'SELECT message_id, sender_id, receiver_id, content, is_read, created_at FROM messages WHERE conversation_id = $1';
    if (before) {
      params.push(before);
      query += ` AND message_id < $${params.length}`;
    }
    params.push(limit);
    query += ` ORDER BY message_id DESC LIMIT $${params.length}`;

    const result = await pool.query(query, params);
    res.json({ success: true, messages: result.rows.reverse() });
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// POST envoie un message dans une conversation, et le pousse en temps réel au
// destinataire s'il est connecté (Socket.io, room = son user_id).
app.post('/api/conversations/:id/messages', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Messages'] */
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Message vide' });
    }

    const { otherUserId } = await assertConversationAccess(req.params.id, req.session.userId);

    const result = await pool.query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, content)
       VALUES ($1, $2, $3, $4)
       RETURNING message_id, sender_id, receiver_id, content, is_read, created_at`,
      [req.params.id, req.session.userId, otherUserId, content.trim()]
    );

    const message = result.rows[0];
    io.to(otherUserId).emit('message:new', { conversationId: Number(req.params.id), message });

    res.status(201).json({ success: true, message });
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// PUT marque comme lus tous les messages reçus dans cette conversation.
app.put('/api/conversations/:id/read', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Messages'] */
  try {
    const { otherUserId } = await assertConversationAccess(req.params.id, req.session.userId);

    await pool.query(
      `UPDATE messages SET is_read = TRUE
       WHERE conversation_id = $1 AND receiver_id = $2 AND is_read = FALSE`,
      [req.params.id, req.session.userId]
    );

    io.to(otherUserId).emit('message:read', { conversationId: Number(req.params.id), readBy: req.session.userId });

    res.json({ success: true });
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - LISTINGS (QDRANT)
   ======================================== */

// GET toutes les annonces
app.get('/api/listings', async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listings = await getAllListings(1000);
    res.json({ success: true, count: listings.length, listings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET mes annonces (tuteur)
app.get('/api/listings/mine', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const userId = req.session.userId;
    const allListings = await getAllListings(1000);
    const myListings = allListings.filter(l => l.tutor_user_id === userId);
    res.json({ success: true, count: myListings.length, listings: myListings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// SEARCH annonces (recherche sémantique)
app.get('/api/listings/search', async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({ error: 'Paramètre de recherche "q" requis' });
    }
    
    const results = await searchListings(q);
    res.json({ success: true, query: q, count: results.length, results });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CREATE nouvelle annonce
app.post('/api/listings', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const { title, description, subject, level, price, tutor_name } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: 'Titre et description requis' });
    }

    // Correction orthographique/grammaticale automatique par IA du titre et de la description
    const corrected = await safeCorrectListingText(title, description);
    const correctedTitle = corrected.title;
    const correctedDescription = corrected.description;

    // Traduction automatique de l'annonce dans toutes les langues du site
    const translations = await safeTranslateListingText(correctedTitle, correctedDescription);

    let tutor_user_id = req.session.userId;
    let tutor_email = null;
    let final_tutor_name = tutor_name || 'Anonymous';
    let tutorLessonMode = 'Visio';
    let tutorVisioTool = 'Zoom';
    let tutorPlaces = ['Visio'];

    if (tutor_user_id) {
      const userResult = await pool.query(
        'SELECT email, first_name, last_name, lesson_mode, visio_tool, lesson_places FROM users WHERE user_id = $1',
        [tutor_user_id]
      );
      if (userResult.rows.length > 0) {
        const u = userResult.rows[0];
        tutor_email = u.email;
        if (!tutor_name || tutor_name === 'Anonymous') {
          final_tutor_name = `${u.first_name || ''} ${u.last_name || ''}`.trim();
        }
        tutorLessonMode = normalizeLessonMode(u.lesson_mode);
        tutorVisioTool = normalizeVisioTool(u.visio_tool);
        tutorPlaces = normalizeTutorPlaces(u.lesson_places);
      }
    }

    const listing = {
      id: Date.now(),
      title: correctedTitle,
      description: correctedDescription,
      subject: subject || 'other',
      level: level || 'intermediate',
      price: parseFloat(price) || 0,
      tutor_name: final_tutor_name || 'Anonymous',
      tutor_email: tutor_email,
      tutor_user_id: tutor_user_id,
      tutor_lesson_mode: tutorLessonMode,
      tutor_visio_tool: tutorVisioTool,
      tutor_places: tutorPlaces,
      translations,
    };

    await indexListing(listing);

    res.status(201).json({ success: true, listing, textCorrected: corrected.corrected });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE annonce (tuteur propriétaire)
app.put('/api/listings/:id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listId = req.params.id;
    const allListings = await getAllListings(1000);
    const existing = allListings.find((l) => String(l.id) === String(listId));

    if (!existing) {
      return res.status(404).json({ error: 'Annonce non trouvée' });
    }

    if (existing.tutor_user_id !== req.session.userId) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    const {
      title,
      description,
      subject,
      level,
      price,
    } = req.body;

    // Correction orthographique/grammaticale automatique par IA du titre et de la description
    const corrected = await safeCorrectListingText(
      title ?? existing.title,
      description ?? existing.description
    );

    // Retraduction automatique de l'annonce dans toutes les langues du site
    const translations = await safeTranslateListingText(corrected.title, corrected.description);

    const updatedListing = {
      ...existing,
      id: existing.id,
      title: corrected.title,
      description: corrected.description,
      subject: subject ?? existing.subject,
      level: level ?? existing.level,
      price: price != null ? parseFloat(price) : existing.price,
      tutor_places: normalizeTutorPlaces(existing.tutor_places),
      tutor_lesson_mode: normalizeLessonMode(existing.tutor_lesson_mode),
      tutor_visio_tool: normalizeVisioTool(existing.tutor_visio_tool),
      created_at: existing.created_at,
      translations,
    };

    await indexListing(updatedListing);
    res.json({ success: true, listing: updatedListing, textCorrected: corrected.corrected });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE une annonce (tuteur)
app.delete('/api/listings/:id', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listId = req.params.id;
    // On va vérifier que l'annonce lui appartient
    const allListings = await getAllListings(1000);
    const listing = allListings.find(l => l.id == listId);
    
    if (!listing) return res.status(404).json({ error: 'Annonce non trouvée' });
    if (listing.tutor_user_id !== req.session.userId) return res.status(403).json({ error: 'Non autorisé' });

    // Bug corrigé : req.params.id est toujours une chaîne, alors que Qdrant attend le
    // même type que l'ID utilisé à l'indexation (entier). Sans ce cast, la suppression
    // échouait systématiquement avec une erreur "Bad Request" côté Qdrant.
    await deleteListing(listing.id);
    res.json({ success: true, message: 'Annonce supprimée' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET engagement stats for multiple listings
app.get('/api/listings/engagement', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingIdsParam = req.query.listing_ids;
    if (!listingIdsParam) {
      return res.json({ interests: {}, favorites: {}, myInterests: [], myFavorites: [] });
    }

    const listingIds = String(listingIdsParam)
      .split(',')
      .map((id) => Number(id))
      .filter((id) => Number.isFinite(id));

    if (listingIds.length === 0) {
      return res.json({ interests: {}, favorites: {}, myInterests: [], myFavorites: [] });
    }

    const interestCountResult = await pool.query(
      `SELECT listing_id, COUNT(*)::int AS count
       FROM listing_interests
       WHERE listing_id = ANY($1)
       GROUP BY listing_id`,
      [listingIds]
    );

    const favoriteCountResult = await pool.query(
      `SELECT listing_id, COUNT(*)::int AS count
       FROM listing_favorites
       WHERE listing_id = ANY($1)
       GROUP BY listing_id`,
      [listingIds]
    );

    const myInterestsResult = await pool.query(
      `SELECT listing_id
       FROM listing_interests
       WHERE student_user_id = $1 AND listing_id = ANY($2)`,
      [req.session.userId, listingIds]
    );

    const myFavoritesResult = await pool.query(
      `SELECT listing_id
       FROM listing_favorites
       WHERE student_user_id = $1 AND listing_id = ANY($2)`,
      [req.session.userId, listingIds]
    );

    const interests = {};
    const favorites = {};

    for (const row of interestCountResult.rows) {
      interests[row.listing_id] = row.count;
    }

    for (const row of favoriteCountResult.rows) {
      favorites[row.listing_id] = row.count;
    }

    res.json({
      interests,
      favorites,
      myInterests: myInterestsResult.rows.map((r) => Number(r.listing_id)),
      myFavorites: myFavoritesResult.rows.map((r) => Number(r.listing_id)),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST mark interest in listing
app.post('/api/listings/:id/interests', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingId = Number(req.params.id);
    if (!Number.isFinite(listingId)) {
      return res.status(400).json({ error: 'ID annonce invalide' });
    }

    const listings = await getAllListings(1000);
    const listing = listings.find((l) => Number(l.id) === listingId);
    if (!listing) {
      return res.status(404).json({ error: 'Annonce non trouvée' });
    }

    if (listing.tutor_user_id === req.session.userId) {
      return res.status(400).json({ error: 'Vous ne pouvez pas montrer un intérêt pour votre propre annonce' });
    }

    await pool.query(
      `INSERT INTO listing_interests (listing_id, student_user_id)
       VALUES ($1, $2)
       ON CONFLICT (listing_id, student_user_id) DO NOTHING`,
      [listingId, req.session.userId]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*)::int AS count FROM listing_interests WHERE listing_id = $1',
      [listingId]
    );

    res.json({ success: true, interested: true, count: countResult.rows[0].count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE remove interest from listing
app.delete('/api/listings/:id/interests', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingId = Number(req.params.id);
    if (!Number.isFinite(listingId)) {
      return res.status(400).json({ error: 'ID annonce invalide' });
    }

    await pool.query(
      'DELETE FROM listing_interests WHERE listing_id = $1 AND student_user_id = $2',
      [listingId, req.session.userId]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*)::int AS count FROM listing_interests WHERE listing_id = $1',
      [listingId]
    );

    res.json({ success: true, interested: false, count: countResult.rows[0].count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET listing interests (owner tutor sees emails, others only count)
app.get('/api/listings/:id/interests', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingId = Number(req.params.id);
    if (!Number.isFinite(listingId)) {
      return res.status(400).json({ error: 'ID annonce invalide' });
    }

    const listings = await getAllListings(1000);
    const listing = listings.find((l) => Number(l.id) === listingId);
    if (!listing) {
      return res.status(404).json({ error: 'Annonce non trouvée' });
    }

    const countResult = await pool.query(
      'SELECT COUNT(*)::int AS count FROM listing_interests WHERE listing_id = $1',
      [listingId]
    );
    const count = countResult.rows[0].count;

    if (listing.tutor_user_id === req.session.userId) {
      const peopleResult = await pool.query(
        `SELECT u.user_id, u.first_name, u.last_name, u.email
         FROM listing_interests li
         JOIN users u ON u.user_id = li.student_user_id
         WHERE li.listing_id = $1
         ORDER BY li.created_at DESC`,
        [listingId]
      );

      return res.json({
        count,
        people: peopleResult.rows.map((row) => ({
          userId: row.user_id,
          firstName: row.first_name || '',
          lastName: row.last_name || '',
          email: row.email,
          fullName: `${row.first_name || ''} ${row.last_name || ''}`.trim()
        }))
      });
    }

    res.json({ count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST add favorite listing
app.post('/api/listings/:id/favorite', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingId = Number(req.params.id);
    if (!Number.isFinite(listingId)) {
      return res.status(400).json({ error: 'ID annonce invalide' });
    }

    await pool.query(
      `INSERT INTO listing_favorites (listing_id, student_user_id)
       VALUES ($1, $2)
       ON CONFLICT (listing_id, student_user_id) DO NOTHING`,
      [listingId, req.session.userId]
    );

    res.json({ success: true, favorited: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE favorite listing
app.delete('/api/listings/:id/favorite', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listingId = Number(req.params.id);
    if (!Number.isFinite(listingId)) {
      return res.status(400).json({ error: 'ID annonce invalide' });
    }

    await pool.query(
      'DELETE FROM listing_favorites WHERE listing_id = $1 AND student_user_id = $2',
      [listingId, req.session.userId]
    );

    res.json({ success: true, favorited: false });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET favorite listing IDs for current user
app.get('/api/favorites', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const result = await pool.query(
      `SELECT listing_id
       FROM listing_favorites
       WHERE student_user_id = $1
       ORDER BY created_at DESC`,
      [req.session.userId]
    );

    const listingIds = result.rows.map((row) => Number(row.listing_id));
    res.json({ success: true, listingIds });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET user's interests
app.get('/api/interests', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const result = await pool.query(
      `SELECT listing_id
       FROM listing_interests
       WHERE student_user_id = $1
       ORDER BY created_at DESC`,
      [req.session.userId]
    );

    const listingIds = result.rows.map((row) => Number(row.listing_id));
    res.json({ success: true, listingIds });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - ANALYSE CV (IA)
   ======================================== */

app.post('/api/analyze-cv', authLimiter, upload.single('cv'), async (req, res) => {
  /* #swagger.tags = ['CV'] */
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'Aucun fichier fourni' });
    }

    const result = await analyzeCVAndGenerateSuggestions(req.file.buffer);
    res.json(result);

  } catch (err) {
    console.error('CV analysis error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ========================================
   ROUTES API - AUTRES
   ======================================== */

// GET requêtes d'aide (mock pour l'instant)
app.get('/api/requests', async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    // TODO: Implémenter la vraie logique
    res.json([]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET balance utilisateur — reflète le vrai solde blockchain (même calcul que /api/profile)
app.get('/api/balance', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const { balance, stats } = await getWalletBalanceAndStats(req.session.userId);
    const transactions = await getTransactionHistory(req.session.userId);
    res.json({ balance, stats, transactions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET shop
app.get('/api/shop', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['General'] */
  try {
    const { balance } = await getWalletBalanceAndStats(req.session.userId);
    res.json({ balance, products: SHOP_PRODUCTS });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST achat boutique — paie en CCT réels depuis le wallet de l'utilisateur vers la
// trésorerie de la boutique.
app.post('/api/purchase', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['General'] */
  try {
    const { productId } = req.body;
    const product = SHOP_PRODUCTS.find((p) => p.id === Number(productId));
    if (!product) {
      return res.status(404).json({ error: 'Produit introuvable' });
    }

    const senderWallet = await getSenderWallet(req.session.userId);
    if (!senderWallet) {
      return res.status(400).json({ error: 'Aucun wallet associé à ce compte' });
    }
    const { walletId: fromWalletId, address: fromAddress, privateKey } = senderWallet;

    const { balance } = await getWalletBalanceAndStats(req.session.userId);
    if (balance < product.price) {
      return res.status(400).json({ error: 'Solde insuffisant' });
    }

    const shopAddress = await getShopTreasuryAddress();
    const result = await sendTransaction(fromAddress, shopAddress, product.price, privateKey);

    await pool.query(
      `INSERT INTO transactions (tx_hash, from_wallet, to_wallet, amount, status, type)
       VALUES ($1, $2, NULL, $3, 'CONFIRMED', 'BURN')`,
      [result.transactionHash, fromWalletId, product.price]
    );

    res.json({ success: true, product, transactionHash: result.transactionHash });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   SWAGGER API DOCUMENTATION
   ======================================== */

const swaggerPath = join(__dirname, 'swagger-output.json');
if (existsSync(swaggerPath)) {
  const swaggerDoc = JSON.parse(readFileSync(swaggerPath, 'utf8'));
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDoc));
  console.log('📖 Swagger docs available at /api/docs');
}

/* ========================================
   DÉMARRAGE DU SERVEUR
   ======================================== */

// httpServer (et non app.listen) : c'est lui qui porte le serveur Socket.io.
// Utiliser app.listen() ici démarrerait un second serveur HTTP indépendant et
// Socket.io ne recevrait jamais aucune connexion.
httpServer.listen(PORT, async () => {
  console.log('========================================');
  console.log(`🚀 CryptoCampus Server`);
  console.log(`📡 Listening on http://localhost:${PORT}`);
  console.log('========================================');
  
  // Initialiser les services externes
  try {
    await ensureFeatureSchema();
    await initQdrantCollection();
    console.log('✅ Qdrant initialized');
  } catch (error) {
    console.error('⚠️  Qdrant initialization failed (continuing anyway)');
  }
  
  console.log('========================================');
  console.log('✅ Server ready to accept connections');
  console.log('========================================');
});

// Gestion gracieuse de l'arrêt
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing server...');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, closing server...');
  await pool.end();
  process.exit(0);
});
