# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Copiar el schema de Prisma primero
COPY prisma ./prisma

# Copiar todo el proyecto NestJS
COPY entregable4-dev-ops ./entregable4-dev-ops

# Cambiar al directorio del proyecto NestJS
WORKDIR /app/entregable4-dev-ops

# Instalar todas las dependencias (incluyendo dev)
RUN npm install

# Generar cliente de Prisma (desde /app/entregable4-dev-ops, el schema está en /app/prisma)
RUN npx prisma generate --schema=../prisma/schema.prisma

# Construir la aplicación
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app

# Instalar Prisma CLI globalmente para migraciones
RUN npm install -g prisma@^6.19.0

# Copiar package.json
COPY entregable4-dev-ops/package*.json ./

# Instalar solo dependencias de producción (esto incluye @prisma/client)
RUN npm install --omit=dev

# Copiar el schema de Prisma
COPY prisma ./prisma

# Copiar el cliente de Prisma generado desde el builder
# Prisma genera el cliente en node_modules/.prisma y node_modules/@prisma
COPY --from=builder /app/entregable4-dev-ops/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/entregable4-dev-ops/node_modules/@prisma ./node_modules/@prisma

# Copiar el código compilado
COPY --from=builder /app/entregable4-dev-ops/dist ./dist

EXPOSE 3000

# Ejecutar migraciones y luego iniciar la aplicación
# docker-compose ya espera a que la DB esté lista (healthcheck + depends_on)
CMD sh -c "prisma migrate deploy --schema=./prisma/schema.prisma || prisma db push --schema=./prisma/schema.prisma --accept-data-loss && node dist/main.js"
