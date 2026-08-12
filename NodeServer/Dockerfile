FROM node:20-alpine

WORKDIR /app

# Outils de compilation nécessaires aux modules natifs (ex: bcrypt) quand le
# binaire précompilé ne peut pas être téléchargé (réseau indisponible/instable) :
# npm se rabat alors sur une compilation depuis les sources via node-gyp, qui a
# besoin de Python et d'un compilateur C++.
RUN apk add --no-cache python3 make g++

# Nettoyer le cache npm
RUN npm cache clean --force

# Copier le package.json
COPY package.json .

# Installer les dépendances
RUN npm install

# Copier les fichiers de l'application
COPY . .

# Générer la documentation Swagger
RUN node swagger.js

# Exposer le port
EXPOSE 3000

# Commande de démarrage
CMD ["npm", "run", "dev"]
