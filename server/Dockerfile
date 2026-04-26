FROM node:22-slim
WORKDIR /app
COPY package.json package-lock.json* tsconfig.json ./
RUN npm ci
COPY src/ ./src/
RUN npx tsc
RUN npm prune --omit=dev
ENV PORT=8080
EXPOSE 8080
CMD ["node", "lib/index.js"]
