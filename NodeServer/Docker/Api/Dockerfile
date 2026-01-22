FROM node:24-alpine

WORKDIR /app

# Force-clean npm state
RUN npm cache clean --force

COPY ./Docker/Api/package.json .

RUN npm install

COPY ./Api ./Api

EXPOSE 3000

CMD ["npm", "run", "dev"]
