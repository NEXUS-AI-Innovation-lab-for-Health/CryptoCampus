# Tests automatisés

## Backend (`NodeServer/tests/`)

Tests d'intégration : ils tapent directement l'API HTTP réelle (pas de mocks de la
base de données/Qdrant/Ganache), exactement comme testé manuellement pendant le
développement. Il faut donc que la stack Docker tourne.

```bash
cd NodeServer

# 1. Démarrer la stack avec les limites de débit désactivées (sinon la suite de
#    tests, qui crée beaucoup de comptes en quelques secondes, se fait bloquer
#    par le rate-limiting — qui lui fonctionne très bien, c'est justement ce
#    qu'on a vérifié en écrivant ces tests !)
npm run test:up

# 2. Lancer les tests
npm test

# 3. Une fois fini, remettre l'API en config normale (rate-limiting actif)
npm run test:down
```

Chaque test crée ses propres comptes/annonces/réservations de test et les supprime
à la fin (voir `tests/helpers.js`). En cas d'échec en cours de route, il peut rester
des comptes `vitest_*@example.com` : sans conséquence, à nettoyer au besoin via
pgAdmin ou un `DELETE FROM users WHERE email LIKE 'vitest_%'`.

Les tests annonces (`listings.test.js`) appellent la vraie traduction IA (Mistral) :
la suite complète prend une dizaine de secondes de plus à cause de ça.

## Frontend (`NodeServer/Application/Frontend/src/**/*.test.js`)

Tests unitaires/composants (Vitest + @vue/test-utils + jsdom), sans dépendance à
l'API ni à Docker — `fetch` est mocké.

```bash
cd NodeServer/Application/Frontend
npm test
```

## Couverture actuelle

- **Backend** : inscription/rôles/parrainage, contrôle d'accès (users, bookings,
  transaction blockchain, CORS), annonces (création/correction/traduction IA/
  recherche/suppression), réservations (dont le bug du créneau qui restait
  "réservé" après annulation), bénéficiaires, bascule étudiant→tuteur, liaison
  LinkedIn (réservée aux tuteurs), mot de passe, photo de profil.
- **Frontend** : composable `useAuth`, logique de détection "première visite"
  du routeur, rendu des icônes de drapeau, logique de choix de rôle à
  l'inscription (Login.vue).

Ce n'est pas une couverture à 100 % (pages comme Reservations.vue, Agenda.vue,
MyCourses.vue n'ont pas de tests dédiés) mais ça couvre les correctifs de
sécurité et les fonctionnalités ajoutées cette session — à étendre au besoin.
