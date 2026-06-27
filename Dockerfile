# ── Stage 1: Build static assets with Maven ──────────────────────────────────
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

COPY pom.xml .
COPY src ./src

# Backend URLs are injected at build time so the generated JS points
# to the correct API endpoints (they are hardcoded into script.js by
# StaticPageGenerator.java at compile time).
ARG BACKEND_USERS_URL=http://localhost:8081
ARG BACKEND_PRODUCTS_URL=http://localhost:8082

RUN echo "BACKEND_USERS_URL=${BACKEND_USERS_URL}" > .env \
 && echo "BACKEND_PRODUCTS_URL=${BACKEND_PRODUCTS_URL}" >> .env \
 && mvn --no-transfer-progress compile exec:java \
        -Dexec.mainClass=com.eval3.frontend.StaticPageGenerator

# ── Stage 2: Serve with nginx (minimal image) ─────────────────────────────────
FROM nginx:alpine
COPY --from=builder /app/output /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
