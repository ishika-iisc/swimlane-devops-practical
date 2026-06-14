FROM node:20-bookworm-slim AS dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-bookworm-slim AS runtime

ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

RUN addgroup --system --gid 1001 nodeapp \
  && adduser --system --uid 1001 --ingroup nodeapp nodeapp

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

USER nodeapp
EXPOSE 3000

CMD ["node", "server.js"]
