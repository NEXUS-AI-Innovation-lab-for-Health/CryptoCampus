import express from 'express';
import { Pool } from 'pg';
import 'dotenv/config';
import multer from 'multer';
import bcrypt from 'bcrypt';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { getAllAccounts, sendTransaction, getBalance, getTransactionDetails } from './blockchain.js';
import { initQdrantCollection, indexListing, searchListings, getAllListings, deleteListing } from './qdrant-service.js';
import { analyzeCVAndGenerateSuggestions } from './cv-analyzer.js';

const app = express();
const PORT = 3000;

/* =========================
   CONFIGURATION GÉNÉRALE
========================= */

app.use(express.json());

// CORS simple (à sécuriser en prod)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// Gestion fichiers statiques
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
app.use(express.static(join(__dirname, '..')));

/* =========================
   BASE DE DONNÉES
========================= */

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

/* =========================
   USERS ROUTES
========================= */

// REGISTER
app.post('/users/register', async (req, res) => {
  try {
    const { email, password, first_name, last_name, role } = req.body;

    if (!email || !password ) {
      return res.status(400).json({ error: 'Champs requis manquants' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const result = await pool.query(
      `INSERT INTO users 
      (email, password_hash, first_name, last_name, role, is_verified, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING user_id, email, first_name, last_name, role, is_verified, created_at`,
      [email, hashedPassword, first_name, last_name, role || 'user', false]
    );

    res.status(201).json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET ALL USERS (sans password)
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, is_verified, created_at, last_login 
       FROM users`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET USER BY ID
app.get('/users/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      `SELECT user_id, email, first_name, last_name, role, is_verified, created_at, last_login
       FROM users WHERE user_id = $1`,
      [user_id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found' });

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET USER BY EMAIL (utilisé par backend auth)
app.post('/users/by-email', async (req, res) => {
  try {
    const { email } = req.body;

    const result = await pool.query(
      `SELECT * FROM users WHERE email = $1`,
      [email]
    );

    res.json(result.rows[0] || null);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE USER
app.put('/users/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { first_name, last_name, role } = req.body;

    const result = await pool.query(
      `UPDATE users
       SET first_name = $1,
           last_name = $2,
           role = $3
       WHERE user_id = $4
       RETURNING user_id, email, first_name, last_name, role, is_verified`,
      [first_name, last_name, role, user_id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found' });

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE USER
app.delete('/users/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      'DELETE FROM users WHERE user_id = $1 RETURNING user_id',
      [user_id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found' });

    res.json({ message: 'User deleted successfully' });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// VERIFY USER
app.patch('/users/:user_id/verify', async (req, res) => {
  try {
    const { user_id } = req.params;

    await pool.query(
      `UPDATE users SET is_verified = true WHERE user_id = $1`,
      [user_id]
    );

    res.json({ message: 'User verified' });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE LAST LOGIN
app.patch('/users/:user_id/last-login', async (req, res) => {
  try {
    const { user_id } = req.params;

    await pool.query(
      `UPDATE users SET last_login = NOW() WHERE user_id = $1`,
      [user_id]
    );

    res.json({ message: 'Last login updated' });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =========================
   BOOKINGS ROUTES
========================= */

// GET ALL BOOKINGS (avec filtre optionnel par utilisateur)
app.get('/bookings', async (req, res) => {
  try {
    const { user_id } = req.query;
    
    let query = `
      SELECT booking_id, user_id, listing_id, title, description, subject,
             start_time, end_time, status, tutor_name, price, notes,
             created_at, updated_at
      FROM bookings
    `;
    
    let params = [];
    if (user_id) {
      query += ` WHERE user_id = $1`;
      params.push(user_id);
    }
    
    query += ` ORDER BY start_time ASC`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET BOOKING BY ID
app.get('/bookings/:booking_id', async (req, res) => {
  try {
    const { booking_id } = req.params;
    
    const result = await pool.query(
      `SELECT * FROM bookings WHERE booking_id = $1`,
      [booking_id]
    );
    
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Booking not found' });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CREATE NEW BOOKING
app.post('/bookings', async (req, res) => {
  try {
    const {
      user_id,
      listing_id,
      title,
      description,
      subject,
      start_time,
      end_time,
      tutor_name,
      price,
      notes
    } = req.body;
    
    if (!user_id || !title || !start_time || !end_time) {
      return res.status(400).json({ error: 'Champs requis manquants' });
    }
    
    const result = await pool.query(
      `INSERT INTO bookings 
      (user_id, listing_id, title, description, subject, start_time, end_time, 
       status, tutor_name, price, notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [user_id, listing_id, title, description, subject, start_time, end_time,
       'pending', tutor_name, price, notes]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE BOOKING
app.put('/bookings/:booking_id', async (req, res) => {
  try {
    const { booking_id } = req.params;
    const {
      title,
      description,
      subject,
      start_time,
      end_time,
      status,
      tutor_name,
      price,
      notes
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
      [title, description, subject, start_time, end_time, status, tutor_name, price, notes, booking_id]
    );
    
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Booking not found' });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE BOOKING STATUS
app.patch('/bookings/:booking_id/status', async (req, res) => {
  try {
    const { booking_id } = req.params;
    const { status } = req.body;
    
    if (!['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }
    
    const result = await pool.query(
      `UPDATE bookings 
       SET status = $1, updated_at = NOW()
       WHERE booking_id = $2
       RETURNING *`,
      [status, booking_id]
    );
    
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Booking not found' });
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE BOOKING
app.delete('/bookings/:booking_id', async (req, res) => {
  try {
    const { booking_id } = req.params;
    
    const result = await pool.query(
      'DELETE FROM bookings WHERE booking_id = $1 RETURNING booking_id',
      [booking_id]
    );
    
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Booking not found' });
    
    res.json({ message: 'Booking deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =========================
   MULTER CONFIG
========================= */

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') cb(null, true);
    else cb(new Error('Seuls les fichiers PDF sont acceptés'));
  }
});

/* =========================
   AUTRES ROUTES (Blockchain, Listings, CV)
========================= */

// Blockchain
app.get('/blockchain/accounts', async (req, res) => {
  try {
    const accounts = await getAllAccounts();
    res.json({ success: true, accounts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/blockchain/balance/:address', async (req, res) => {
  try {
    const balance = await getBalance(req.params.address);
    res.json({ success: true, ...balance });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/blockchain/transaction', async (req, res) => {
  try {
    const { fromAddress, toAddress, amount } = req.body;
    const result = await sendTransaction(fromAddress, toAddress, amount);
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== QDRANT / LISTINGS ENDPOINTS ==========

// Récupérer toutes les annonces
app.get('/listings', async (req, res) => {
  try {
    const listings = await getAllListings();
    res.json({ success: true, count: listings.length, listings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rechercher des annonces
app.get('/listings/search', async (req, res) => {
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

// Créer une nouvelle annonce
app.post('/listings', async (req, res) => {
  try {
    const { title, description, subject, level, price, tutor_name } = req.body;
    const id = Date.now();

    const listing = {
      id,
      title,
      description,
      subject,
      level,
      price: parseFloat(price),
      tutor_name,
      created_at: new Date().toISOString()
    };

    await indexListing(listing);

    res.status(201).json({ success: true, listing });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Analyze CV
app.post('/analyze-cv', upload.single('cv'), async (req, res) => {
  try {
    if (!req.file)
      return res.status(400).json({ success: false, error: 'Aucun fichier fourni' });

    const result = await analyzeCVAndGenerateSuggestions(req.file.buffer);
    res.json(result);

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/* =========================
   START SERVER
========================= */

app.listen(PORT, async () => {
  console.log(`Server running on http://localhost:${PORT}`);
  
  // Initialiser Qdrant
  try {
    await initQdrantCollection();
  } catch (error) {
    console.error('⚠️  Qdrant initialization failed, but server is running');
  }
});
