import express from "express";
import { fileURLToPath } from "url";
import path from "path";

const app = express();
const PORT = 3000;

app.use(express.json());

app.listen(3000, () => {
  console.log("Server running on port 3000");
});

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pagesDirectory = path.join(__dirname, "../Front/pages");
const stylesDirectory = path.join(__dirname, "../Front/styles");
const jsDirectory = path.join(__dirname, "../Front/js");

// Serve CSS files from the 'styles' directory
app.use('/styles', express.static(stylesDirectory));
app.use('/js', express.static(jsDirectory));

function getPage(pageName) {
  let pagePath = path.join(pagesDirectory, `${pageName}.html`);
  //console.log(pagePath);
  return pagePath;
}

// Setting up all pages routes
app.get("/", (req, res) => {
  res.redirect('home');
});

app.get("/home", (req, res) => {
  res.sendFile(getPage('home'))
});

app.get("/balance", (req, res) => {
  res.sendFile(getPage('balance'))
});

app.get("/shop", (req, res) => {
  res.sendFile(getPage('shop'))
});

app.get("/create_request", (req, res) => {
  res.sendFile(getPage('create_request'))
});

app.get("/login", (req, res) => {
  res.sendFile(getPage('login'))
});

app.get("/testApi", async (req, res) => {
  try {
    const response = await fetch("http://localhost:81/users", {
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

