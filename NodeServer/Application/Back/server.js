import express from "express";
import { fileURLToPath } from "url";
import path from "path";
import session from "express-session";
import bcrypt from "bcrypt";
import cors from "cors";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "../Frontend/dist")));
app.use(
  cors({
    origin: "*",
    credentials: true,
  }),
);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

const loginRoute = "login";
const logoutRoute = "logout";
const apiBaseUrl = "http://api:3000";

// Removed EJS setup - now serving Vue SPA

app.use(
  session({
    name: "sessionId",
    secret:
      process.env.SESSION_SECRET ||
      "ZONGOSECRETCODEULTRASUPERSECURETUCONNAISCLASECURITEQUOITIAKOLAREPONDSSTP",
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      secure: false, // true en HTTPS
      sameSite: "lax",
      maxAge: 1000 * 60 * 60,
    },
  }),
);

//---------//---------Méthodes---------//---------//

//Middleware d'authentification
function authGuard(options) {
  return (req, res, next) => {
    const isLogged = !!req.session.userId;
    console.log(
      `AuthGuard: isLogged=${isLogged}, options=${JSON.stringify(options)}`,
    );
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

//---------//---------Routes---------//---------//

// Serve Vue SPA for all client routes
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

app.get("/home", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

app.get(loginRoute, (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

app.get("/balance", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

app.get("/shop", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

app.get("/create_request", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});
app.get("/blockchain-demo", (req, res) => {
  res.sendFile(path.join(pagesDirectory, "blockchain-demo.html"));
});

app.get("/listings-demo", (req, res) => {
  res.sendFile(path.join(pagesDirectory, "listings-demo.html"));
});

app.get("/create-listing-cv", (req, res) => {
  res.sendFile(path.join(pagesDirectory, "create-listing-cv.html"));
});

app.get(
  logoutRoute,
  authGuard({ mustBeLogged: true, redirectTo: "/home" }),
  (req, res) => {
    res.render("logout", { isLogged: true });
  },
);

app.post(
  logoutRoute,
  authGuard({ mustBeLogged: true, redirectTo: "/home" }),
  (req, res) => {
    req.session.destroy((err) => {
      if (err) {
        console.error("Error destroying session:", err);
      }
    });
    res.redirect("home");
  },
);

app.get(logoutRoute, (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});

// API Endpoints

// Check authentication status
app.get("/api/check-auth", (req, res) => {
  const isAuthenticated = !!req.session.userId;
  res.json({ isAuthenticated, userId: req.session.userId });
});

app.get("/api/profile", async (req, res) => {
  const userId = req.session.userId;
  if (userId) {
    try {
      const response = await fetch(`${apiBaseUrl}/users/${userId}`, {
        method: "GET",
        headers: { "Content-Type": "application/json" },
      });
      const data = await response.json();
      res.json(data);
    } catch (error) {
      console.error("Users error:", error);
      res.status(500).json({ message: "Failed to get current user data" });
    }
  }
});

// Login endpoint
app.post(
  "/api/login",
  authGuard({ mustBeGuest: true, redirectTo: logoutRoute }),
  async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password required" });
    }

    // Appel à ton API métier pour récupérer l'utilisateur
    const response = await fetch(`${apiBaseUrl}/users/by-email`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email }),
    });

    const user = await response.json();

    console.log("User from API:", JSON.stringify(user, null, 2));

    if (!user || !user.user_id) {
      console.log("User not found or no ID");
      return res.status(401).json({ message: "Invalid credentials" });
    }

    if (!user.password_hash) {
      console.log("User has no password field");
      return res.status(401).json({ message: "Invalid credentials" });
    }

    try {
      const valid =
        (await bcrypt.compare(password, user.password_hash)) ||
        password === user.password_hash;

      if (!valid) {
        console.log("Password does not match");
        return res.status(401).json({ message: "Invalid credentials" });
      }

      req.session.userId = user.user_id;
      console.log("User logged in:", user.user_id);
      res.json({ message: "Connected", token: user.user_id });
    } catch (error) {
      console.error("Bcrypt error:", error.message);
      return res.status(500).json({ message: "Server error" });
    }
  },
);

// Logout endpoint
app.post(
  "/api/logout",
  authGuard({ mustBeLogged: true, redirectTo: loginRoute }),
  (req, res) => {
    req.session.destroy((err) => {
      if (err) {
        console.error("Error destroying session:", err);
        return res.status(500).json({ message: "Logout failed" });
      }
      res.json({ message: "Logged out successfully" });
    });
  },
);

// Register endpoint
app.post("/api/register", async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res
      .status(400)
      .json({ message: "Name, email, and password required" });
  }

  try {
    // Call your API to create user
    const response = await fetch(`${apiBaseUrl}/users`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, password }),
    });

    if (response.ok) {
      res.json({ message: "User created successfully" });
    } else {
      res.status(400).json({ message: "Failed to create user" });
    }
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Get balance endpoint
app.get(
  "/api/balance",
  authGuard({ mustBeLogged: true, redirectTo: loginRoute }),
  async (req, res) => {
    try {
      // This would call your blockchain/API to get balance
      // For now, returning mock data
      res.json({
        balance: 150,
        stats: {
          helpedCount: 5,
          totalEarned: 250,
          requestsCreated: 3,
        },
        transactions: [
          {
            id: 1,
            description: "Earned from helping student",
            amount: 50,
            date: new Date(),
          },
          {
            id: 2,
            description: "Spent on rewards",
            amount: -30,
            date: new Date(),
          },
        ],
      });
    } catch (error) {
      console.error("Balance error:", error);
      res.status(500).json({ message: "Failed to get balance" });
    }
  },
);

// Get requests endpoint
app.get("/api/requests", async (req, res) => {
  try {
    // This would call your API to get requests
    res.json([]);
  } catch (error) {
    console.error("Requests error:", error);
    res.status(500).json({ message: "Failed to get requests" });
  }
});

// Get users endpoint
app.get("/api/users", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/users`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });
    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error("Users error:", error);
    res.status(500).json({ message: "Failed to get users" });
  }
});

// Get shop endpoint
app.get(
  "/api/shop",
  authGuard({ mustBeLogged: true, redirectTo: loginRoute }),
  async (req, res) => {
    try {
      res.json({
        balance: 150,
        products: [
          {
            id: 1,
            name: "Amazon Voucher",
            description: "$20 Amazon Gift Card",
            price: 100,
            category: "giftcard",
            emoji: "🎁",
          },
          {
            id: 2,
            name: "Netflix Pass",
            description: "1 Month Netflix Premium",
            price: 80,
            category: "premium",
            emoji: "📺",
          },
        ],
      });
    } catch (error) {
      console.error("Shop error:", error);
      res.status(500).json({ message: "Failed to get shop" });
    }
  },
);

// Create request endpoint
app.post(
  "/api/create-request",
  authGuard({ mustBeLogged: true, redirectTo: loginRoute }),
  async (req, res) => {
    const { subject, title, description, urgency, reward, deadline } = req.body;

    if (!subject || !title || !description || !reward) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    try {
      // Call your API to create request
      const response = await fetch(`${apiBaseUrl}/requests`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          subject,
          title,
          description,
          urgency,
          reward,
          deadline,
          userId: req.session.userId,
        }),
      });

      if (response.ok) {
        res.json({ message: "Request created successfully" });
      } else {
        res.status(400).json({ message: "Failed to create request" });
      }
    } catch (error) {
      console.error("Create request error:", error);
      res.status(500).json({ message: "Server error" });
    }
  },
);

// Purchase endpoint
app.post(
  "/api/purchase",
  authGuard({ mustBeLogged: true, redirectTo: loginRoute }),
  async (req, res) => {
    const { productId, amount } = req.body;

    if (!productId || !amount) {
      return res
        .status(400)
        .json({ message: "Product ID and amount required" });
    }

    try {
      // Call your API to process purchase
      res.json({ message: "Purchase successful" });
    } catch (error) {
      console.error("Purchase error:", error);
      res.status(500).json({ message: "Purchase failed" });
    }
  },
);

// Legacy test endpoints (optional)

app.get("/blockchain-test", (req, res) => {
  res.sendFile(getPage("blockchain-test"));
});

app.get("/create-listing-cv", (req, res) => {
  res.sendFile(getPage("create-listing-cv"));
});

app.get("/testApi", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/users/register`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "Lamelo@bdlm.com",
        password: "Lamelo@bdlm.com",
        first_name: "Lamelo@bdlm.com",
        last_name: "Lamelo@bdlm.com",
        role: "user",
      }),
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

// Bookings API routes (proxy to api_crypto container)
app.get("/api/bookings", async (req, res) => {
  try {
    const userId = req.query.user_id;
    const url = userId ? `${apiBaseUrl}/bookings?user_id=${userId}` : `${apiBaseUrl}/bookings`;
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error("Bookings error:", error);
    res.status(500).json({ error: "Failed to get bookings" });
  }
});

app.get("/api/bookings/:booking_id", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/bookings/${req.params.booking_id}`);
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error("Booking error:", error);
    res.status(500).json({ error: "Failed to get booking" });
  }
});

app.post("/api/bookings", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/bookings`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body)
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error("Create booking error:", error);
    res.status(500).json({ error: "Failed to create booking" });
  }
});

app.put("/api/bookings/:booking_id", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/bookings/${req.params.booking_id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body)
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error("Update booking error:", error);
    res.status(500).json({ error: "Failed to update booking" });
  }
});

app.patch("/api/bookings/:booking_id/status", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/bookings/${req.params.booking_id}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body)
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error("Update status error:", error);
    res.status(500).json({ error: "Failed to update booking status" });
  }
});

app.delete("/api/bookings/:booking_id", async (req, res) => {
  try {
    const response = await fetch(`${apiBaseUrl}/bookings/${req.params.booking_id}`, {
      method: "DELETE"
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error("Delete booking error:", error);
    res.status(500).json({ error: "Failed to delete booking" });
  }
});

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../Frontend/dist/index.html"));
});
