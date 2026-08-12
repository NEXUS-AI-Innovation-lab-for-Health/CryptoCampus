import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Uniquement les tests backend : Application/Frontend a sa propre suite/config
    // (plugin Vue requis pour transformer les .vue, absent ici).
    include: ['tests/**/*.test.js'],
    // Tests d'intégration qui tapent le même serveur/la même base : on les exécute
    // fichier par fichier pour éviter les interférences d'état partagé (comptes de
    // test qui se marchent dessus, etc.), au prix d'un peu de vitesse.
    fileParallelism: false,
    testTimeout: 20000,
    hookTimeout: 20000,
  },
});
