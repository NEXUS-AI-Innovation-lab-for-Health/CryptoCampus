import { describe, it, expect } from 'vitest';
import { makeClient, registerAndLogin, deleteAccount, uniqueEmail } from './helpers.js';

describe('Inscription et rôles', () => {
  it('crée un compte tuteur sans code de parrainage', async () => {
    const { client, user } = await registerAndLogin({ role: 'tutor' });
    expect(user.role).toBe('TUTOR');
    expect(user.referral_code).toMatch(/^[A-Z0-9]{8}$/);
    await deleteAccount(client);
  });

  it("refuse la création sans rôle choisi", async () => {
    const client = makeClient();
    const res = await client.post('/api/register', {
      email: uniqueEmail('norole'),
      password: 'testpass123',
    });
    expect(res.status).toBe(400);
  });

  it("refuse un compte étudiant sans code de parrainage", async () => {
    const client = makeClient();
    const res = await client.post('/api/register', {
      email: uniqueEmail('nocode'),
      password: 'testpass123',
      desired_role: 'student',
    });
    expect(res.status).toBe(400);
  });

  it('refuse un code de parrainage invalide', async () => {
    const client = makeClient();
    const res = await client.post('/api/register', {
      email: uniqueEmail('badcode'),
      password: 'testpass123',
      desired_role: 'student',
      referral_code: 'NOPE0000',
    });
    expect(res.status).toBe(400);
  });

  it("crée un compte étudiant avec un code de parrainage valide, et l'ajoute aux bénéficiaires du parrain", async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({
      role: 'student',
      referralCode: tutor.user.referral_code,
    });
    expect(student.user.role).toBe('STUDENT');

    const beneficiaries = await tutor.client.get('/api/beneficiaries');
    expect(beneficiaries.status).toBe(200);
    expect(beneficiaries.data.beneficiaries.some((b) => b.label.includes(student.user.first_name))).toBe(true);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it("n'attribue jamais le rôle ADMIN via l'inscription publique, même si demandé explicitement", async () => {
    const client = makeClient();
    const email = uniqueEmail('hacker');
    const res = await client.post('/api/register', {
      email,
      password: 'testpass123',
      desired_role: 'admin',
    });
    // 'admin' n'est pas une valeur acceptée par resolveRoleFromReferral (student/tutor uniquement)
    expect(res.status).toBe(400);

    // Même en essayant de faire passer "ADMIN" comme "tutor" avec un rôle caché,
    // le compte créé (s'il l'est) ne doit jamais être ADMIN.
    const res2 = await client.post('/api/register', {
      email: uniqueEmail('hacker2'),
      password: 'testpass123',
      desired_role: 'tutor',
      role: 'ADMIN',
    });
    expect(res2.data.user.role).toBe('TUTOR');

    const login = await client.post('/api/login', { email: res2.data.user.email, password: 'testpass123' });
    expect(login.status).toBe(200);
    await deleteAccount(client);
  });

  it('refuse la connexion avec un mauvais mot de passe', async () => {
    const { client, email } = await registerAndLogin({ role: 'tutor' });
    const fresh = makeClient();
    const res = await fresh.post('/api/login', { email, password: 'wrongpassword' });
    expect(res.status).toBe(401);
    await deleteAccount(client);
  });

  it('/api/check-auth reflète correctement l\'état de connexion', async () => {
    const anon = makeClient();
    const before = await anon.get('/api/check-auth');
    expect(before.data.isAuthenticated).toBe(false);

    const { client } = await registerAndLogin({ role: 'tutor' });
    const after = await client.get('/api/check-auth');
    expect(after.data.isAuthenticated).toBe(true);
    expect(after.data.role).toBe('TUTOR');

    await deleteAccount(client);
    const afterDelete = await client.get('/api/check-auth');
    expect(afterDelete.data.isAuthenticated).toBe(false);
  });
});
