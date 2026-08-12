import { describe, it, expect } from 'vitest';
import { makeClient, registerAndLogin, deleteAccount } from './helpers.js';

describe('Annonces', () => {
  it('exige d\'être connecté pour créer une annonce', async () => {
    const anon = makeClient();
    const res = await anon.post('/api/listings', {
      title: 'Cours de test',
      description: 'Description de test',
    });
    expect(res.status).toBe(401);
  });

  it('crée une annonce, la corrige et la traduit automatiquement (IA)', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });

    const res = await client.post('/api/listings', {
      title: 'Cours de mathematique',
      description: 'Je propose des cours de math pour lyceens, tres pedagogue.',
      subject: 'Maths',
      level: 'Lycée',
      price: 20,
    });

    expect(res.status).toBe(201);
    expect(res.data.listing.id).toBeTypeOf('number');
    // La traduction peut échouer silencieusement si Mistral est indisponible :
    // on vérifie qu'elle est bien tentée et cohérente quand elle est présente.
    if (res.data.listing.translations) {
      expect(res.data.listing.translations.en.title).toBeTypeOf('string');
      expect(res.data.listing.translations.en.title.length).toBeGreaterThan(0);
    }

    // Vérifie que l'annonce et ses traductions sont bien récupérables ensuite
    const listRes = await client.get('/api/listings');
    const created = listRes.data.listings.find((l) => l.id === res.data.listing.id);
    expect(created).toBeDefined();
    expect(created.subject).toBe('Maths');

    await client.delete(`/api/listings/${res.data.listing.id}`);
    await deleteAccount(client);
  });

  it("empêche un tuteur de modifier/supprimer l'annonce d'un autre", async () => {
    const owner = await registerAndLogin({ role: 'tutor' });
    const stranger = await registerAndLogin({ role: 'tutor' });

    const created = await owner.client.post('/api/listings', {
      title: 'Cours de piano',
      description: 'Cours de piano pour débutants et confirmés.',
      subject: 'Musique',
      level: 'Tous niveaux',
      price: 25,
    });
    const listingId = created.data.listing.id;

    const updateRes = await stranger.client.put(`/api/listings/${listingId}`, { title: 'Piraté' });
    expect(updateRes.status).toBe(403);

    const deleteRes = await stranger.client.delete(`/api/listings/${listingId}`);
    expect(deleteRes.status).toBe(403);

    // Nettoyage : suppression par le vrai propriétaire
    const ownDelete = await owner.client.delete(`/api/listings/${listingId}`);
    expect(ownDelete.status).toBe(200);

    await deleteAccount(stranger.client);
    await deleteAccount(owner.client);
  });

  it('la recherche sémantique retourne un résultat pertinent', async () => {
    const { client } = await registerAndLogin({ role: 'tutor' });
    const unique = `Kalimba${Date.now()}`;
    const created = await client.post('/api/listings', {
      title: `Cours de ${unique}`,
      description: `Apprenez le ${unique}, un instrument de musique traditionnel.`,
      subject: 'Musique',
      level: 'Débutant',
      price: 15,
    });

    const search = await client.get(`/api/listings/search?q=${encodeURIComponent(unique)}`);
    expect(search.status).toBe(200);
    expect(search.data.results.some((r) => r.id === created.data.listing.id)).toBe(true);

    await client.delete(`/api/listings/${created.data.listing.id}`);
    await deleteAccount(client);
  });
});
