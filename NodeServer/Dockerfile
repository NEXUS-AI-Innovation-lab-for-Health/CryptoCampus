FROM node:24-alpine

WORKDIR /app

# Nettoyer le cache npm
RUN npm cache clean --force

# Copier le package.json
COPY package.json .

# Installer les dépendances
RUN npm install

# Copier les fichiers de l'application
COPY . .

# Exposer le port
EXPOSE 3000

# Commande de démarrage
CMD ["npm", "run", "dev"]
