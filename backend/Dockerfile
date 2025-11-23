# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Copiar el schema de Prisma primero
COPY prisma ./prisma

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar todas las dependencias (incluyendo dev) y limpiar caché
RUN npm install && npm cache clean --force

# Generar cliente de Prisma (el schema está en ./prisma)
RUN NODE_TLS_REJECT_UNAUTHORIZED=0 npx prisma generate --schema=./prisma/schema.prisma

# Copiar el resto del código fuente
COPY . .

# Construir la aplicación
RUN npm run build



# Production stage
FROM node:20-alpine
WORKDIR /app

# Crear usuario no root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Instalar Prisma CLI globalmente (necesario para migrate deploy / db push)
# IMPORTANTÍSIMO: esto debe hacerse ANTES del USER appuser
RUN npm install -g prisma@^6.19.0 && npm cache clean --force

# Copiar package.json
COPY package*.json ./

# Instalar solo dependencias de producción (esto incluye @prisma/client) y limpiar caché
RUN npm install --omit=dev && npm cache clean --force

# Copiar el schema de Prisma
COPY prisma ./prisma

# Generar el cliente de Prisma en producción (antes de cambiar al usuario no-root)
RUN NODE_TLS_REJECT_UNAUTHORIZED=0 npx prisma generate --schema=./prisma/schema.prisma

# Copiar el código compilado (antes de cambiar al usuario no-root)
COPY --from=builder /app/dist ./dist

# Cambiar permisos de la carpeta /app al usuario no-root
RUN chown -R appuser:appgroup /app

# Cambiar a usuario no-root
USER appuser

EXPOSE 3000

# Comando para ejecutar migraciones y luego iniciar la aplicación
CMD ["sh", "-c", "if [ -d ./prisma/migrations ] && [ \"$(ls -A ./prisma/migrations 2>/dev/null)\" ]; then npx prisma migrate deploy --schema=./prisma/schema.prisma; else npx prisma db push --schema=./prisma/schema.prisma --accept-data-loss; fi && node dist/main.js"]
