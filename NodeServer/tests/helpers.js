// Utilitaires partagés par les tests d'intégration.
// Ces tests tapent directement l'API HTTP réelle (docker compose doit tourner en
// local : `docker compose up -d`), exactement comme on l'a fait manuellement tout
// au long du développement de ces fonctionnalités. On évite ainsi de dupliquer la
// config DB/Qdrant/Ganache dans un environnement de test séparé.

export const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1';

let counter = 0;
// Identifiant unique par test pour ne jamais entrer en collision entre lancements
// et pouvoir nettoyer facilement à la fin de chaque test.
export function uniqueEmail(prefix = 'test') {
  counter += 1;
  return `vitest_${prefix}_${Date.now()}_${counter}@example.com`;
}

// Client HTTP minimal qui conserve les cookies de session entre les appels
// (comme un navigateur), sans dépendance externe.
export function makeClient() {
  let cookie = '';

  async function request(method, path, body) {
    const headers = {};
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    if (cookie) headers['Cookie'] = cookie;

    const res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      redirect: 'manual',
    });

    const setCookie = res.headers.get('set-cookie');
    if (setCookie) {
      cookie = setCookie.split(';')[0];
    }

    let data = null;
    const text = await res.text();
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }

    return { status: res.status, data, headers: res.headers };
  }

  return {
    get: (path) => request('GET', path),
    post: (path, body) => request('POST', path, body ?? {}),
    put: (path, body) => request('PUT', path, body ?? {}),
    patch: (path, body) => request('PATCH', path, body ?? {}),
    delete: (path) => request('DELETE', path),
    async postForm(path, formData) {
      const headers = {};
      if (cookie) headers['Cookie'] = cookie;
      const res = await fetch(`${BASE_URL}${path}`, { method: 'POST', headers, body: formData });
      const setCookie = res.headers.get('set-cookie');
      if (setCookie) cookie = setCookie.split(';')[0];
      const text = await res.text();
      let data = null;
      try { data = text ? JSON.parse(text) : null; } catch { data = text; }
      return { status: res.status, data };
    },
  };
}

// Crée un compte + connecte le client. Retourne { client, user, email, password }.
export async function registerAndLogin({ role = 'tutor', referralCode, firstName = 'Test', lastName = 'User' } = {}) {
  const client = makeClient();
  const email = uniqueEmail(role);
  const password = 'testpass123';

  const body = {
    email,
    password,
    first_name: firstName,
    last_name: lastName,
    desired_role: role,
  };
  if (referralCode) body.referral_code = referralCode;

  const registerRes = await client.post('/api/register', body);
  if (registerRes.status !== 201) {
    throw new Error(`Échec inscription (${registerRes.status}): ${JSON.stringify(registerRes.data)}`);
  }

  const loginRes = await client.post('/api/login', { email, password });
  if (loginRes.status !== 200) {
    throw new Error(`Échec connexion (${loginRes.status}): ${JSON.stringify(loginRes.data)}`);
  }

  return { client, user: registerRes.data.user, email, password };
}

// Nettoie un compte de test via la route DELETE /api/account (utilise le client
// déjà connecté), pour ne laisser aucune donnée de test derrière soi.
export async function deleteAccount(client) {
  await client.delete('/api/account');
}
