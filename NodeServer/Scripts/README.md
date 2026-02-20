# Scripts de gestion du projet
## ⚠️ Problème possible sous WSL

Si vous obtenez l’erreur suivante :
```bash
-bash: ./cleanLineEndings.sh: cannot execute: required file not found
```

ou :
```bash
/usr/bin/env: ‘bash\r’: No such file or directory
```

Cela signifie que le script contient des fins de ligne Windows (CRLF) au lieu du format Linux (LF).

### ✅ Correction

Exécuter la commande suivante depuis WSL à la racine du projet :
```bash
sed -i 's/\r$//' cleanLineEndings.sh
```

Puis relancer :
```bash
chmod +x cleanLineEndings.sh
./cleanLineEndings.sh
```

## 🧹 cleanLineEndings.sh

Le script cleanLineEndings.sh sert à nettoyer les autres scripts du projet en supprimant les caractères \r (retours chariot Windows).
Il permet d’éviter les erreurs d’exécution sous Linux / WSL.

# 📜 Description des scripts
### buildVueApp.sh

Construit l’application Vue.js (génération du build de production).

### cleanLineEndings.sh

Supprime les fins de ligne Windows (\r) des scripts pour assurer leur compatibilité Linux.

### dumpDB.sh

Effectue un export (dump) de la base de données.

### quickStartAll.sh

Démarre les services si ils sont simplement arrêtés (et pas supprimés).

### quickStopAll.sh

Arrête simplement les services du projet.

### reloadContainerFront.sh

Reload l'application Vue.js du front end.

### restoreDB.sh

Restaure la base de données à partir d’un dump.

### startAll.sh

Crée et démarre l’ensemble des services (backend, frontend, base de données, etc.).

### stopAll.sh

Arrête et supprime l’ensemble des services du projet ainsi que les volumes.