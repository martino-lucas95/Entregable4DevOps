# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Aceptar build arg para la URL de la API
ARG VITE_API_URL=http://localhost:3000
ENV VITE_API_URL=$VITE_API_URL

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto de los archivos
COPY . .

# Construir la aplicación
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app

# Crear usuario no root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser


# Instalar serve para servir los archivos estáticos
RUN npm install -g serve

# Copiar los archivos construidos desde el builder
COPY --from=builder /app/dist ./dist

EXPOSE 5173

# Servir la aplicación
CMD ["serve", "-s", "dist", "-l", "5173"]

