import { describe, it, expect } from 'vitest';
import { registerAndLogin, deleteAccount, makeClient } from './helpers.js';

// Un PNG 1x1 minimal valide, pour tester l'upload d'avatar sans dépendance externe.
const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

describe('Bénéficiaires', () => {
  it("ajoute, liste et retire un bénéficiaire", async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });

    const addRes = await client.post('/api/beneficiaries', {
      label: 'Ami de test',
      address: '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
    });
    expect(addRes.status).toBe(201);

    const listRes = await client.get('/api/beneficiaries');
    expect(listRes.data.beneficiaries.some((b) => b.beneficiary_id === addRes.data.beneficiary.beneficiary_id)).toBe(true);

    const delRes = await client.delete(`/api/beneficiaries/${addRes.data.beneficiary.beneficiary_id}`);
    expect(delRes.status).toBe(200);

    await deleteAccount(client);
  });

  it('refuse une adresse blockchain mal formée', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/beneficiaries', { label: 'Invalide', address: 'pas-une-adresse' });
    expect(res.status).toBe(400);
    await deleteAccount(client);
  });

  it("ne peut pas supprimer le bénéficiaire d'un autre utilisateur", async () => {
    const owner = await registerAndLogin({ role: 'tutor' });
    const stranger = await registerAndLogin({ role: 'tutor' });

    const addRes = await owner.client.post('/api/beneficiaries', {
      label: 'Confidentiel',
      address: '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
    });

    const res = await stranger.client.delete(`/api/beneficiaries/${addRes.data.beneficiary.beneficiary_id}`);
    expect(res.status).toBe(404);

    await deleteAccount(stranger.client);
    await deleteAccount(owner.client);
  });
});

describe('Devenir tuteur', () => {
  it('un étudiant peut basculer en tuteur de façon permanente', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const res = await student.client.post('/api/profile/become-tutor', {
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places: ['Visio'],
    });
    expect(res.status).toBe(200);
    expect(res.data.role).toBe('TUTOR');

    const profile = await student.client.get('/api/profile');
    expect(profile.data.role).toBe('TUTOR');

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('un tuteur ne peut pas re-basculer (déjà tuteur)', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/profile/become-tutor', {});
    expect(res.status).toBe(403);
    await deleteAccount(client);
  });
});

describe('LinkedIn (réservé aux tuteurs)', () => {
  it("un étudiant ne peut pas démarrer la liaison LinkedIn", async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const res = await student.client.get('/api/auth/linkedin/link');
    expect(res.status).toBe(403);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('un tuteur peut démarrer la liaison LinkedIn (redirection vers LinkedIn)', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.get('/api/auth/linkedin/link');
    expect([301, 302, 303, 307, 308]).toContain(res.status);
    await deleteAccount(client);
  });
});

describe('Mot de passe', () => {
  it('refuse la mise à jour avec un mauvais mot de passe actuel', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/reset-password', {
      currentPassword: 'mauvais-mdp',
      newPassword: 'nouveaumdp123',
    });
    expect(res.status).toBe(401);
    await deleteAccount(client);
  });

  it('met à jour le mot de passe et permet de se reconnecter avec le nouveau', async () => {
    const { client, email } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/reset-password', {
      currentPassword: 'testpass123',
      newPassword: 'nouveaumdp123',
    });
    expect(res.status).toBe(200);

    const fresh = makeClient();
    const login = await fresh.post('/api/login', { email, password: 'nouveaumdp123' });
    expect(login.status).toBe(200);

    await deleteAccount(client);
  });
});

describe('Photo de profil', () => {
  it('upload puis supprime une photo de profil', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });

    const bytes = Uint8Array.from(atob(TINY_PNG_BASE64), (c) => c.charCodeAt(0));
    const form = new FormData();
    form.append('avatar', new Blob([bytes], { type: 'image/png' }), 'avatar.png');

    const uploadRes = await client.postForm('/api/profile/avatar', form);
    expect(uploadRes.status).toBe(200);
    expect(uploadRes.data.avatar_url).toMatch(/^\/api\/uploads\/avatars\//);

    const profile = await client.get('/api/profile');
    expect(profile.data.avatar_url).toBe(uploadRes.data.avatar_url);

    const delRes = await client.delete('/api/profile/avatar');
    expect(delRes.status).toBe(200);

    await deleteAccount(client);
  });

  it('refuse un upload sans fichier', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const res = await client.post('/api/profile/avatar');
    expect(res.status).toBe(400);
    await deleteAccount(client);
  });
});
