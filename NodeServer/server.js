/* ========================================
   CRYPTOCAMPUS - SERVEUR API
   ========================================
   Ce serveur expose uniquement les routes /api/*
   Le frontend est servi par un container Nginx séparé
   ======================================== */

import express from 'express';
import { Pool } from 'pg';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync, existsSync } from 'fs';
import session from 'express-session';
import bcrypt from 'bcrypt';
import cors from 'cors';
import multer from 'multer';
import swaggerUi from 'swagger-ui-express';
import 'dotenv/config';

// Services métier
import { getAllAccounts, sendTransaction, getBalance, getTransactionDetails } from './Api/blockchain.js';
import { initQdrantCollection, indexListing, searchListings, getAllListings, deleteListing } from './Api/qdrant-service.js';
import { analyzeCVAndGenerateSuggestions } from './Api/cv-analyzer.js';

/* ========================================
   CONFIGURATION DE BASE
   ======================================== */

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares généraux
app.use(express.json());
app.use(cors({
  origin: '*',
  credentials: true,
}));

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

app.use(session({
  name: 'sessionId',
  secret: process.env.SESSION_SECRET || 'ZONGOSECRETCODEULTRASUPERSECURETUCONNAISCLASECURITEQUOITIAKOLAREPONDSSTP',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // true en production avec HTTPS
    sameSite: 'lax',
    maxAge: 1000 * 60 * 60, // 1 heure
  },
}));

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

    // Récupérer toutes les adresses Ganache disponibles
    const ganacheAccounts = await getAllAccounts();
    
    if (!ganacheAccounts || ganacheAccounts.length === 0) {
      throw new Error('Aucun compte Ganache disponible');
    }

    // Récupérer les adresses déjà assignées
    const assignedAddresses = await pool.query(
      'SELECT public_address FROM wallets WHERE blockchain = $1',
      ['ethereum']
    );

    const assignedSet = new Set(assignedAddresses.rows.map(row => row.public_address.toLowerCase()));

    // Trouver la première adresse disponible
    let availableAddress = null;
    for (const account of ganacheAccounts) {
      if (!assignedSet.has(account.address.toLowerCase())) {
        availableAddress = account.address;
        break;
      }
    }

    if (!availableAddress) {
      // Si toutes les adresses sont prises, réutiliser la première
      availableAddress = ganacheAccounts[0].address;
    }

    // Créer le wallet dans la base de données
    await pool.query(
      `INSERT INTO wallets (user_id, public_address, blockchain, created_at)
       VALUES ($1, $2, $3, NOW())`,
      [userId, availableAddress, 'ethereum']
    );

    console.log(`✅ Adresse blockchain assignée: ${availableAddress} -> User ${userId}`);
  } catch (error) {
    console.error('Erreur lors de l\'assignation d\'adresse blockchain:', error);
    throw error;
  }
}

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
        'POST /api/cv/analyze': 'Analyser un CV (PDF) et obtenir des suggestions'
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
        'SELECT role, email FROM users WHERE user_id = $1',
        [req.session.userId]
      );
      
      if (result.rows.length > 0) {
        return res.json({ 
          isAuthenticated, 
          userId: req.session.userId,
          role: result.rows[0].role,
          email: result.rows[0].email
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
app.post('/api/login', async (req, res) => {
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
      lastName: user.last_name
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
      console.error('Logout error:', err);
      return res.status(500).json({ error: 'Erreur lors de la déconnexion' });
    }
    res.json({ message: 'Déconnecté avec succès' });
  });
});

// Register
app.post('/api/register', async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    const { email, password, first_name, last_name, role } = req.body;

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

    // Normaliser le rôle (convertir en majuscules)
    const normalizedRole = (role || 'student').toUpperCase();
    
    // Valider le rôle
    const validRoles = ['STUDENT', 'TUTOR', 'ADMIN'];
    if (!validRoles.includes(normalizedRole)) {
      return res.status(400).json({ error: 'Rôle invalide' });
    }

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(password, 12);

    // Créer l'utilisateur
    const result = await pool.query(
      `INSERT INTO users 
      (email, password_hash, first_name, last_name, role, is_verified, created_at)
      VALUES ($1, $2, $3, $4, $5::user_role, false, NOW())
      RETURNING user_id, email, first_name, last_name, role, created_at`,
      [email, hashedPassword, first_name || null, last_name || null, normalizedRole]
    );

    const newUser = result.rows[0];

    // Assigner automatiquement une adresse blockchain
    try {
      await assignBlockchainAddress(newUser.user_id);
    } catch (walletError) {
      console.error('Erreur assignation wallet:', walletError);
      // Ne pas faire échouer l'inscription si l'assignation échoue
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

// Profil utilisateur
app.get('/api/profile', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Auth'] */
  try {
    // Récupérer les infos utilisateur
    const userResult = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, is_verified, created_at, last_login
       FROM users WHERE user_id = $1`,
      [req.session.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const user = userResult.rows[0];
    let balance = 0;
    let blockchainAddress = null;

    // Récupérer l'adresse blockchain de l'utilisateur depuis la table wallets
    let walletResult = await pool.query(
      `SELECT public_address, blockchain FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
      [req.session.userId]
    );

    // Si l'utilisateur n'a pas de wallet, lui en assigner un
    if (walletResult.rows.length === 0) {
      try {
        await assignBlockchainAddress(req.session.userId);
        // Récupérer à nouveau le wallet créé
        walletResult = await pool.query(
          `SELECT public_address, blockchain FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
          [req.session.userId]
        );
      } catch (assignError) {
        console.error('Erreur création wallet:', assignError);
      }
    }

    if (walletResult.rows.length > 0) {
      blockchainAddress = walletResult.rows[0].public_address;
      
      // Récupérer le solde réel depuis Ganache
      try {
        const balanceData = await getBalance(blockchainAddress);
        balance = parseFloat(balanceData.balanceEth);
      } catch (balanceError) {
        console.error('Erreur récupération solde Ganache:', balanceError);
        balance = 0;
      }
    }

    // Calculer les statistiques dynamiquement depuis la base de données
    
    // 1. Nombre d'étudiants aidés (participations confirmées où l'utilisateur est le créateur du service)
    const helpedCountResult = await pool.query(
      `SELECT COUNT(DISTINCT sp.user_id) as count
       FROM service_participations sp
       JOIN services s ON sp.service_id = s.service_id
       WHERE s.created_by = $1 AND sp.status = 'CONFIRMED'`,
      [req.session.userId]
    );
    const helpedCount = parseInt(helpedCountResult.rows[0]?.count || 0);

    // 2. Total des coins gagnés (transactions confirmées reçues)
    const walletIdResult = await pool.query(
      `SELECT wallet_id FROM wallets WHERE user_id = $1 AND blockchain = 'ethereum' LIMIT 1`,
      [req.session.userId]
    );
    
    let totalEarned = 0;
    if (walletIdResult.rows.length > 0) {
      const walletId = walletIdResult.rows[0].wallet_id;
      const earnedResult = await pool.query(
        `SELECT COALESCE(SUM(amount), 0) as total
         FROM transactions
         WHERE to_wallet = $1 AND status = 'CONFIRMED'`,
        [walletId]
      );
      totalEarned = parseFloat(earnedResult.rows[0]?.total || 0);
    }

    // 3. Nombre de services/requêtes créés
    const requestsCreatedResult = await pool.query(
      `SELECT COUNT(*) as count FROM services WHERE created_by = $1`,
      [req.session.userId]
    );
    const requestsCreated = parseInt(requestsCreatedResult.rows[0]?.count || 0);

    const stats = {
      helpedCount,
      totalEarned,
      requestsCreated
    };

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

    // Détruire la session
    req.session.destroy((err) => {
      if (err) {
        console.error('Erreur destruction session:', err);
      }
    });

    res.json({ message: 'Compte supprimé avec succès' });

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

// GET tous les utilisateurs
app.get('/api/users', async (req, res) => {
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

// GET un utilisateur par ID
app.get('/api/users/:user_id', async (req, res) => {
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

// UPDATE utilisateur
app.put('/api/users/:user_id', async (req, res) => {
  /* #swagger.tags = ['Users'] */
  try {
    const { first_name, last_name, role } = req.body;

    const result = await pool.query(
      `UPDATE users
       SET first_name = COALESCE($1, first_name),
           last_name = COALESCE($2, last_name),
           role = COALESCE($3, role)
       WHERE user_id = $4
       RETURNING user_id, email, first_name, last_name, role, is_verified`,
      [first_name, last_name, role, req.params.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE utilisateur
app.delete('/api/users/:user_id', async (req, res) => {
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

    if (listing_id) {
      params.push(listing_id);
      query += ` AND ta.listing_id = $${params.length}`;
    }

    if (tutor_user_id) {
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

// POST créer des créneaux (tuteur uniquement)
app.post('/api/availability', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    // Vérifier que l'utilisateur est bien un TUTOR
    const userResult = await pool.query(
      'SELECT role FROM users WHERE user_id = $1',
      [req.session.userId]
    );
    if (userResult.rows.length === 0 || userResult.rows[0].role !== 'TUTOR') {
      return res.status(403).json({ error: 'Seuls les tuteurs peuvent créer des créneaux' });
    }

    // Accepter soit un seul créneau soit un tableau
    let slots = req.body;
    if (!Array.isArray(slots)) {
      slots = [slots];
    }

    const created = [];
    for (const slot of slots) {
      const { listing_id, start_time, end_time } = slot;
      if (!start_time || !end_time) {
        return res.status(400).json({ error: 'start_time et end_time sont requis' });
      }
      if (new Date(end_time) <= new Date(start_time)) {
        return res.status(400).json({ error: 'end_time doit être après start_time' });
      }

      // Vérifier qu'il n'y a pas de chevauchement pour ce tuteur
      const overlap = await pool.query(
        `SELECT slot_id FROM tutor_availability
         WHERE tutor_user_id = $1
           AND is_booked = FALSE
           AND tsrange(start_time, end_time) && tsrange($2::timestamp, $3::timestamp)`,
        [req.session.userId, start_time, end_time]
      );
      if (overlap.rows.length > 0) {
        return res.status(409).json({ error: `Créneau en conflit avec un créneau existant (${start_time})` });
      }

      const result = await pool.query(
        `INSERT INTO tutor_availability (tutor_user_id, listing_id, start_time, end_time)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [req.session.userId, listing_id || null, start_time, end_time]
      );
      created.push(result.rows[0]);
    }

    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ error: err.message });
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

// GET toutes les réservations (avec filtre optionnel par user)
app.get('/api/bookings', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const { user_id } = req.query;
    
    let query = `
      SELECT booking_id, user_id, listing_id, title, description, subject,
             start_time, end_time, status, tutor_name, price, notes,
             created_at, updated_at
      FROM bookings
    `;
    
    const params = [];
    if (user_id) {
      query += ' WHERE user_id = $1';
      params.push(user_id);
    }
    
    query += ' ORDER BY start_time ASC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET une réservation par ID
app.get('/api/bookings/:booking_id', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const result = await pool.query(
      'SELECT * FROM bookings WHERE booking_id = $1',
      [req.params.booking_id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
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

// UPDATE réservation
app.put('/api/bookings/:booking_id', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const {
      title, description, subject, start_time, end_time,
      status, tutor_name, price, notes
    } = req.body;
    
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
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE statut réservation
app.patch('/api/bookings/:booking_id/status', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const { status } = req.body;
    
    if (!['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }
    
    const result = await pool.query(
      `UPDATE bookings 
       SET status = $1, updated_at = NOW()
       WHERE booking_id = $2
       RETURNING *`,
      [status, req.params.booking_id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE réservation
app.delete('/api/bookings/:booking_id', async (req, res) => {
  /* #swagger.tags = ['Bookings'] */
  try {
    const result = await pool.query(
      'DELETE FROM bookings WHERE booking_id = $1 RETURNING booking_id',
      [req.params.booking_id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }
    
    res.json({ message: 'Réservation supprimée avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - BLOCKCHAIN
   ======================================== */

// GET tous les comptes blockchain
app.get('/api/blockchain/accounts', async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const accounts = await getAllAccounts();
    res.json({ success: true, accounts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET balance d'un compte
app.get('/api/blockchain/balance/:address', async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const balance = await getBalance(req.params.address);
    res.json({ success: true, ...balance });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST transaction blockchain
app.post('/api/blockchain/transaction', async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    const { fromAddress, toAddress, amount } = req.body;
    
    if (!fromAddress || !toAddress || !amount) {
      return res.status(400).json({ error: 'Paramètres manquants' });
    }
    
    const result = await sendTransaction(fromAddress, toAddress, amount);
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - LISTINGS (QDRANT)
   ======================================== */

// GET toutes les annonces
app.get('/api/listings', async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const listings = await getAllListings();
    res.json({ success: true, count: listings.length, listings });
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
app.post('/api/listings', async (req, res) => {
  /* #swagger.tags = ['Listings'] */
  try {
    const { title, description, subject, level, price, tutor_name } = req.body;
    
    if (!title || !description) {
      return res.status(400).json({ error: 'Titre et description requis' });
    }
    
    const listing = {
      id: Date.now(),
      title,
      description,
      subject: subject || 'other',
      level: level || 'intermediate',
      price: parseFloat(price) || 0,
      tutor_name: tutor_name || 'Anonymous',
      created_at: new Date().toISOString()
    };

    await indexListing(listing);

    res.status(201).json({ success: true, listing });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES API - ANALYSE CV (IA)
   ======================================== */

app.post('/api/analyze-cv', upload.single('cv'), async (req, res) => {
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

// GET balance utilisateur (mock)
app.get('/api/balance', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['Blockchain'] */
  try {
    // TODO: Intégrer avec la blockchain
    res.json({
      balance: 150,
      stats: {
        helpedCount: 5,
        totalEarned: 250,
        requestsCreated: 3,
      },
      transactions: []
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET shop (mock)
app.get('/api/shop', authGuard({ mustBeLogged: true }), async (req, res) => {
  /* #swagger.tags = ['General'] */
  try {
    res.json({
      balance: 150,
      products: [
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
      ]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* ========================================
   ROUTES PAGES DE DÉMO (HTML statiques)
   ======================================== */

// Pages de démonstration des services
app.get('/listings-demo', (req, res) => {
  res.sendFile(join(__dirname, 'Application/Front/pages/listings-demo.html'));
});

app.get('/blockchain-demo', (req, res) => {
  res.sendFile(join(__dirname, 'Application/Front/pages/blockchain-demo.html'));
});

app.get('/create-listing-cv', (req, res) => {
  res.sendFile(join(__dirname, 'Application/Front/pages/create-listing-cv.html'));
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

app.listen(PORT, async () => {
  console.log('========================================');
  console.log(`🚀 CryptoCampus Server`);
  console.log(`📡 Listening on http://localhost:${PORT}`);
  console.log('========================================');
  
  // Initialiser les services externes
  try {
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
