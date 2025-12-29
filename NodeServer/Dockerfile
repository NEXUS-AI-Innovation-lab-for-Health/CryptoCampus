FROM node:24-alpine

WORKDIR /app

# Force-clean npm state
RUN npm cache clean --force

COPY package.json .

RUN npm install

COPY ./Application .

EXPOSE 3000

CMD ["npm", "run", "dev"]
