import express, { json } from 'express';
import {Pool} from 'pg';
import 'dotenv/config';
import { getAllAccounts, sendTransaction, getBalance, getTransactionDetails } from './blockchain-example.js';
import { initQdrantCollection, indexListing, searchListings, getAllListings, deleteListing } from './qdrant-service.js';

const app = express();
const PORT = 3000;

// Initialiser Qdrant au démarrage
initQdrantCollection().catch(console.error);

// Middleware CORS pour permettre les requêtes depuis n'importe quelle origine
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Middleware to parse JSON requests
app.use(express.json());

// Servir les fichiers statiques depuis le dossier parent (où se trouve test-listings.html)
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Servir les fichiers depuis le dossier parent de Api (NodeServer)
app.use(express.static(join(__dirname, '..')));

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Create a user
app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    const result = await pool.query(
      'INSERT INTO users(name, email) VALUES($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all users
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a user by ID
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update a user
app.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email } = req.body;
    const result = await pool.query(
      'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING *',
      [name, email, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a user
app.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== BLOCKCHAIN / GANACHE ENDPOINTS ==========

// Récupérer tous les comptes Ganache avec leurs soldes
app.get('/blockchain/accounts', async (req, res) => {
  try {
    const accounts = await getAllAccounts();
    res.json({
      success: true,
      totalAccounts: accounts.length,
      accounts
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Récupérer le solde d'un compte spécifique
app.get('/blockchain/balance/:address', async (req, res) => {
  try {
    const { address } = req.params;
    const balance = await getBalance(address);
    res.json({
      success: true,
      ...balance
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Envoyer une transaction entre deux comptes
app.post('/blockchain/transaction', async (req, res) => {
  try {
    const { fromAddress, toAddress, amount } = req.body;
    
    if (!fromAddress || !toAddress || !amount) {
      return res.status(400).json({ 
        error: 'fromAddress, toAddress et amount sont requis' 
      });
    }

    const result = await sendTransaction(fromAddress, toAddress, amount);
    res.json({
      success: true,
      ...result
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Récupérer les détails d'une transaction
app.get('/blockchain/transaction/:hash', async (req, res) => {
  try {
    const { hash } = req.params;
    const details = await getTransactionDetails(hash);
    res.json({
      success: true,
      transaction: details
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== TUTORING LISTINGS / QDRANT ENDPOINTS ==========

// Créer une nouvelle annonce et l'indexer dans Qdrant
app.post('/listings', async (req, res) => {
  try {
    const { title, description, subject, level, price, tutor_name } = req.body;
    
    if (!title || !description || !subject || !level || !price || !tutor_name) {
      return res.status(400).json({ 
        error: 'Tous les champs sont requis (title, description, subject, level, price, tutor_name)' 
      });
    }

    // Générer un ID unique (dans un vrai projet, utiliser UUID ou auto-increment DB)
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
    
    res.status(201).json({
      success: true,
      listing
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rechercher des annonces par mots-clés (Qdrant search)
app.get('/listings/search', async (req, res) => {
  try {
    const { q, limit } = req.query;
    
    if (!q) {
      return res.status(400).json({ 
        error: 'Le paramètre "q" (query) est requis' 
      });
    }

    const results = await searchListings(q, limit ? parseInt(limit) : 10);
    
    res.json({
      success: true,
      query: q,
      count: results.length,
      results
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Récupérer toutes les annonces
app.get('/listings', async (req, res) => {
  try {
    const { limit } = req.query;
    const results = await getAllListings(limit ? parseInt(limit) : 50);
    
    res.json({
      success: true,
      count: results.length,
      listings: results
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Supprimer une annonce
app.delete('/listings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await deleteListing(parseInt(id));
    
    res.json({
      success: true,
      message: `Annonce #${id} supprimée`
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
