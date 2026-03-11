import swaggerAutogen from 'swagger-autogen';

const doc = {
  info: {
    title: 'CryptoCampus API',
    version: '2.0.0',
    description: 'API for CryptoCampus — student tutoring platform with blockchain payments, semantic search, and AI-powered CV analysis.',
  },
  host: 'localhost',
  schemes: ['http'],
  tags: [
    { name: 'Auth',        description: 'Authentication & session management' },
    { name: 'Users',       description: 'User account management' },
    { name: 'Bookings',    description: 'Tutoring session bookings' },
    { name: 'Listings',    description: 'Tutor listings with semantic search' },
    { name: 'Blockchain',  description: 'Ethereum wallet & transactions via Ganache' },
    { name: 'CV',          description: 'AI-powered CV analysis (Mistral)' },
  ],
};

const outputFile = './swagger-output.json';
const routes = ['./server.js'];

swaggerAutogen({ openapi: '3.0.0' })(outputFile, routes, doc);
