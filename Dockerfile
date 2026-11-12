
# syntax=docker/dockerfile:1

# Etapa 1: build
FROM node:24-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install
RUN npm ci

COPY . .
RUN npm run build

# Etapa 2: migrator
FROM build AS migrator
ENV NODE_ENV=production \
    NPM_CONFIG_UPDATE_NOTIFIER=false
USER node
CMD ["npx", "prisma", "migrate", "deploy"]

# Etapa 3: runtime
FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

# Pasta de logs
RUN mkdir -p /app/logs && chown node:node /app/logs
USER node

EXPOSE 3000
CMD ["node", "dist/main.js"]
