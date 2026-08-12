import { describe, it, expect } from 'vitest';
import { BASE_URL, makeClient, registerAndLogin, deleteAccount } from './helpers.js';

// Ces tests couvrent les failles de sécurité corrigées cette session : ils doivent
// rester au vert en permanence, sinon une régression a réintroduit une faille.
describe('Sécurité : contrôle d\'accès', () => {
  it('/api/users est inaccessible sans authentification', async () => {
    const anon = makeClient();
    expect((await anon.get('/api/users')).status).toBe(401);
  });

  it('/api/users refuse un utilisateur connecté non-admin', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.get('/api/users');
    expect(res.status).toBe(403);
    await deleteAccount(client);
  });

  it("un tuteur ne peut pas modifier le rôle d'un autre compte via /api/users/:id", async () => {
    const victim = await registerAndLogin({ role: 'tutor' });
    const attacker = await registerAndLogin({ role: 'tutor' });

    const res = await attacker.client.put(`/api/users/${victim.user.user_id}`, { role: 'ADMIN' });
    expect(res.status).toBe(403);

    await deleteAccount(attacker.client);
    await deleteAccount(victim.client);
  });

  it('/api/bookings est inaccessible sans authentification', async () => {
    const anon = makeClient();
    expect((await anon.get('/api/bookings')).status).toBe(401);
  });

  it("un utilisateur ne peut pas lire/modifier/supprimer la réservation d'un autre", async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });
    const stranger = await registerAndLogin({ role: 'tutor' });

    // Crée un créneau et une réservation pour avoir un booking_id réel à cibler
    const slotRes = await tutor.client.post('/api/availability', [
      { start_time: futureIso(1), end_time: futureIso(1, 1) },
    ]);
    if (slotRes.status === 201 && slotRes.data?.[0]?.slot_id) {
      const bookingRes = await student.client.post('/api/bookings', {
        slot_ids: [slotRes.data[0].slot_id],
        title: 'Test',
      });
      const bookingId = bookingRes.data?.[0]?.booking_id;
      if (bookingId) {
        expect((await stranger.client.get(`/api/bookings/${bookingId}`)).status).toBe(403);
        expect((await stranger.client.patch(`/api/bookings/${bookingId}/status`, { status: 'cancelled' })).status).toBe(403);
        expect((await stranger.client.delete(`/api/bookings/${bookingId}`)).status).toBe(403);
      }
    }

    await deleteAccount(stranger.client);
    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('/api/blockchain/transaction exige une authentification', async () => {
    const anon = makeClient();
    const res = await anon.post('/api/blockchain/transaction', {
      toAddress: '0x0000000000000000000000000000000000dEaD',
      amount: 1,
    });
    expect(res.status).toBe(401);
  });

  it("/api/blockchain/transaction ignore une adresse source fournie par le client (utilise toujours le wallet du compte connecté)", async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/blockchain/transaction', {
      fromAddress: '0x000000000000000000000000000000000FAKE1',
      toAddress: '0x0000000000000000000000000000000000dEaD',
      amount: 1,
    });
    // La transaction doit réussir (elle part du VRAI wallet du compte, pas de celui fourni)
    // ou échouer proprement, mais ne doit jamais utiliser fromAddress tel quel.
    if (res.status === 200) {
      expect(res.data.from.address.toLowerCase()).not.toBe('0x000000000000000000000000000000000fake1');
    }
    await deleteAccount(client);
  });

  it('rejette une requête cross-origin non autorisée (CORS)', async () => {
    const res = await fetch(`${BASE_URL}/api/listings`, {
      headers: { Origin: 'http://evil.example.com' },
    });
    const allowOrigin = res.headers.get('access-control-allow-origin');
    expect(allowOrigin).not.toBe('http://evil.example.com');
    expect(allowOrigin).not.toBe('*');
  });

  // Le rate-limiting sur /api/login n'est pas vérifié ici : cette suite tourne
  // avec AUTH_RATE_LIMIT relevé (docker-compose.test.yml) pour pouvoir créer
  // librement des comptes de test. Il est vérifié manuellement (curl/production)
  // et par la config elle-même (server.js: authLimiter).
});

function futureIso(daysFromNow, extraHours = 0) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  d.setHours(10 + extraHours, 0, 0, 0);
  return d.toISOString();
}
