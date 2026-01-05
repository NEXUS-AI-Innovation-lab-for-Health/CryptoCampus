FROM node:24-alpine

WORKDIR /app

# Force-clean npm state
RUN npm cache clean --force

COPY ./Docker/Node/package.json .

RUN npm install

COPY ./Application ./Application

EXPOSE 3000

CMD ["npm", "run", "dev"]
