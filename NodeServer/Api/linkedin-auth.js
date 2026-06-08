const LINKEDIN_AUTH_URL = 'https://www.linkedin.com/oauth/v2/authorization';
const LINKEDIN_TOKEN_URL = 'https://www.linkedin.com/oauth/v2/accessToken';
const LINKEDIN_USERINFO_URL = 'https://api.linkedin.com/v2/userinfo';

// Construit l'URL d'autorisation LinkedIn (OpenID Connect)
export function getLinkedInAuthorizationUrl(state) {
    const params = new URLSearchParams({
        response_type: 'code',
        client_id: process.env.LINKEDIN_CLIENT_ID,
        redirect_uri: process.env.LINKEDIN_REDIRECT_URI,
        scope: 'openid profile email',
        state,
    });

    return `${LINKEDIN_AUTH_URL}?${params.toString()}`;
}

// Échange le code d'autorisation contre un access token
export async function exchangeCodeForToken(code) {
    const params = new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        client_id: process.env.LINKEDIN_CLIENT_ID,
        client_secret: process.env.LINKEDIN_CLIENT_SECRET,
        redirect_uri: process.env.LINKEDIN_REDIRECT_URI,
    });

    const response = await fetch(LINKEDIN_TOKEN_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString(),
    });

    if (!response.ok) {
        throw new Error(`Échange du code LinkedIn échoué (${response.status})`);
    }

    const data = await response.json();
    return data.access_token;
}

// Récupère les infos de profil (OpenID Connect userinfo)
export async function fetchLinkedInProfile(accessToken) {
    const response = await fetch(LINKEDIN_USERINFO_URL, {
        headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
        throw new Error(`Récupération du profil LinkedIn échouée (${response.status})`);
    }

    const data = await response.json();

    return {
        email: data.email,
        emailVerified: !!data.email_verified,
        firstName: data.given_name || null,
        lastName: data.family_name || null,
    };
}
