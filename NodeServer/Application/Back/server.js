import express from "express";
import { fileURLToPath } from "url";
import path from "path";
import session from 'express-session';
import bcrypt from 'bcrypt';


const app = express();
const PORT = 3000;

app.use(express.json());

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pagesDirectory = path.join(__dirname, "../Front/pages");
const stylesDirectory = path.join(__dirname, "../Front/styles");
const jsDirectory = path.join(__dirname, "../Front/js");
const srcDirectory = path.join(__dirname, "../Front/src");
const viewsDirectory = path.join(__dirname, "../Front/views");

const loginRoute = '/login';
const logoutRoute = '/logout';
const apiBaseUrl = 'http://api_crypto:3000';

// View engine setup
app.set('view engine', 'ejs');
app.set('views', viewsDirectory);

// Serve CSS files from the 'styles' directory
app.use('/styles', express.static(stylesDirectory));
app.use('/js', express.static(jsDirectory));
app.use('/src', express.static(srcDirectory));

app.use(session({
  name: 'sessionId',
  secret: process.env.SESSION_SECRET || 'ZONGOSECRETCODEULTRASUPERSECURETUCONNAISCLASECURITEQUOITIAKOLAREPONDSSTP',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // true en HTTPS
    sameSite: 'lax',
    maxAge: 1000 * 60 * 60
  }
}));

//---------//---------Méthodes---------//---------//

//Middleware d'authentification
function authGuard(options) {
  return (req, res, next) => {
    const isLogged = !!req.session.userId;
    console.log(`AuthGuard: isLogged=${isLogged}, options=${JSON.stringify(options)}`);
    console.log(`Session data: ${JSON.stringify(req.session)}`);

    if (options.mustBeLogged && !isLogged) {
      return res.redirect(options.redirectTo);
    }

    if (options.mustBeGuest && isLogged) {
      return res.redirect(options.redirectTo);
    }

    next();
  };
}


function getPage(pageName) {
  let pagePath = path.join(pagesDirectory, `${pageName}.html`);
  //console.log(pagePath);
  return pagePath;
}

//---------//---------Routes---------//---------//

app.get("/", (req, res) => {
  res.redirect('home');
});

app.get("/home", (req, res) => {
  res.render('home', { isLogged: !!req.session.userId })
});

app.get("/balance", (req, res) => {
  res.render('balance', { isLogged: !!req.session.userId })
});

app.get("/shop", (req, res) => {
  res.render('shop', { isLogged: !!req.session.userId })
});

app.get("/create_request", (req, res) => {
  res.render('create_request', { isLogged: !!req.session.userId })
});

app.get(logoutRoute, authGuard({ mustBeLogged: true, redirectTo: '/home' }), (req, res) => {
  res.render('logout', { isLogged: true })
})

app.post(logoutRoute, authGuard({ mustBeLogged: true, redirectTo: '/home' }), (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Error destroying session:', err);
    }
  });
  res.redirect('home');
})

app.get(loginRoute, authGuard({ mustBeGuest: true, redirectTo: logoutRoute }), (req, res) => {
  res.render('login', { isLogged: false })
});

app.post(loginRoute, authGuard({ mustBeGuest: true, redirectTo: logoutRoute }), async (req, res) => {
  const { email, password } = req.body;

  console.log('Login attempt:', { email, passwordLength: password?.length });

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password required' });
  }

  // Appel à ton API métier pour récupérer l'utilisateur
  const response = await fetch(`${apiBaseUrl}/users/by-email`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });

  const user = await response.json();

  console.log('User from API:', JSON.stringify(user, null, 2));

  if (!user || !user.user_id) {
    console.log('User not found or no ID');
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  if (!user.password_hash) {
    console.log('User has no password field');
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  console.log('Comparing passwords...');
  console.log('Input password length:', password.length);
  console.log('Stored password length:', user.password_hash.length);
  console.log('Stored password starts with:', user.password_hash.substring(0, 10));

  try {
    const valid = await bcrypt.compare(password, user.password_hash) || password === user.password_hash;
    
    console.log('Bcrypt comparison result:', valid);
    
    if (!valid) {
      console.log('Password does not match');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    req.session.userId = user.user_id;
    console.log('User logged in:', user.user_id);
    res.json({ message: 'Connected', token: user.user_id });
  } catch (error) {
    console.error('Bcrypt error:', error.message);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.get("/test-listings", (req, res) => {
  res.sendFile(getPage('test-listings'))
});

app.get("/blockchain-test", (req, res) => {
  res.sendFile(getPage('blockchain-test'))
});

app.get("/create-listing-cv", (req, res) => {
  res.sendFile(getPage('create-listing-cv'))
});

app.get("/testApi", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/users`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        name: "Tiakola Melo",
        email: "Lamelo@bdlm.com"
      })
    });

    if (!response.ok) {
      return res
        .status(response.status)
        .send(`Request failed with status ${response.status}`);
    }

    const body = await response.json(); // or response.json()
    console.log(body);

    res.send(body);
  } catch (error) {
    console.error(error);
    res.status(500).send("Internal Server Error");
  }
});



