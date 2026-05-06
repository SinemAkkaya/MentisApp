// Tek bir PrismaClient örneği — singleton pattern.
// Her import'ta yeniden oluşturmamak için.
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

module.exports = prisma;
