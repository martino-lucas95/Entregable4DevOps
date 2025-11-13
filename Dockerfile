# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Copiar el schema de Prisma primero
COPY prisma ./prisma

# Copiar todo el proyecto NestJS
COPY backend ./backend

# Cambiar al directorio del proyecto NestJS
WORKDIR /app/backend

# Instalar todas las dependencias (incluyendo dev)
RUN npm install

# Generar cliente de Prisma (desde /app/backend, el schema está en /app/prisma)
RUN npx prisma generate --schema=../prisma/schema.prisma

# Construir la aplicación
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app

# Instalar Prisma CLI y crear usuario no-root en una sola capa
RUN npm install -g prisma@^6.19.0 \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup
    
USER appuser

# Copiar package.json
COPY backend/package*.json ./

# Instalar solo dependencias de producción (esto incluye @prisma/client)
RUN npm install --omit=dev

# Copiar el schema de Prisma
COPY prisma ./prisma

# Copiar el cliente de Prisma generado desde el builder
# Prisma genera el cliente en node_modules/.prisma y node_modules/@prisma
COPY --from=builder /app/backend/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/backend/node_modules/@prisma ./node_modules/@prisma

# Copiar el código compilado
COPY --from=builder /app/backend/dist ./dist

EXPOSE 3000

# Ejecutar migraciones y luego iniciar la aplicación
# docker-compose ya espera a que la DB esté lista (healthcheck + depends_on)
CMD sh -c "prisma migrate deploy --schema=./prisma/schema.prisma || prisma db push --schema=./prisma/schema.prisma --accept-data-loss && node dist/main.js"
