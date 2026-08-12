import { describe, it, expect } from 'vitest';
import { registerAndLogin, deleteAccount, makeClient } from './helpers.js';

function futureIso(daysFromNow, hour = 10) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  d.setHours(hour, 0, 0, 0);
  return d.toISOString();
}

async function createSlot(tutorClient, daysFromNow, hour) {
  const res = await tutorClient.post('/api/availability', [
    { start_time: futureIso(daysFromNow, hour), end_time: futureIso(daysFromNow, hour + 1) },
  ]);
  expect(res.status).toBe(201);
  return res.data[0];
}

describe('Réservations', () => {
  it('un étudiant peut réserver un créneau publié par un tuteur', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const slot = await createSlot(tutor.client, 2, 10);

    const booking = await student.client.post('/api/bookings', {
      slot_ids: [slot.slot_id],
      title: 'Cours de test',
      tutor_name: `${tutor.user.first_name} ${tutor.user.last_name}`,
    });
    expect(booking.status).toBe(201);
    expect(booking.data[0].status).toBe('pending');

    // Le créneau ne doit plus apparaître comme disponible
    const availability = await student.client.get(`/api/availability?tutor_user_id=${tutor.user.user_id}`);
    expect(availability.data.some((s) => s.slot_id === slot.slot_id)).toBe(false);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('un créneau annulé redevient disponible (bug corrigé cette session)', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const slot = await createSlot(tutor.client, 3, 14);
    const booking = await student.client.post('/api/bookings', {
      slot_ids: [slot.slot_id],
      title: 'Cours à annuler',
    });
    const bookingId = booking.data[0].booking_id;

    // Le créneau est bien marqué indisponible juste après la réservation
    let availability = await student.client.get(`/api/availability?tutor_user_id=${tutor.user.user_id}`);
    expect(availability.data.some((s) => s.slot_id === slot.slot_id)).toBe(false);

    // Annulation par l'étudiant
    const cancelRes = await student.client.patch(`/api/bookings/${bookingId}/status`, { status: 'cancelled' });
    expect(cancelRes.status).toBe(200);
    expect(cancelRes.data.status).toBe('cancelled');

    // Le créneau doit être redevenu disponible
    availability = await student.client.get(`/api/availability?tutor_user_id=${tutor.user.user_id}`);
    expect(availability.data.some((s) => s.slot_id === slot.slot_id)).toBe(true);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('la suppression d\'une réservation libère aussi le créneau', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const slot = await createSlot(tutor.client, 4, 9);
    const booking = await student.client.post('/api/bookings', {
      slot_ids: [slot.slot_id],
      title: 'Cours à supprimer',
    });
    const bookingId = booking.data[0].booking_id;

    const deleteRes = await student.client.delete(`/api/bookings/${bookingId}`);
    expect(deleteRes.status).toBe(200);

    const availability = await tutor.client.get(`/api/availability?tutor_user_id=${tutor.user.user_id}`);
    expect(availability.data.some((s) => s.slot_id === slot.slot_id)).toBe(true);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });

  it('un tuteur ne peut pas créer de créneau hors des heures pile/demie', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const d = new Date();
    d.setDate(d.getDate() + 5);
    d.setHours(10, 15, 0, 0); // 10h15 : invalide

    const res = await tutor.client.post('/api/availability', [
      { start_time: d.toISOString(), end_time: new Date(d.getTime() + 3600000).toISOString() },
    ]);
    expect(res.status).toBe(400);

    await deleteAccount(tutor.client);
  });

  it('seul un tuteur peut créer des créneaux de disponibilité', async () => {
    const tutor = await registerAndLogin({ role: 'tutor' });
    const student = await registerAndLogin({ role: 'student', referralCode: tutor.user.referral_code });

    const res = await student.client.post('/api/availability', [
      { start_time: futureIso(6, 10), end_time: futureIso(6, 11) },
    ]);
    expect(res.status).toBe(403);

    await deleteAccount(student.client);
    await deleteAccount(tutor.client);
  });
});
