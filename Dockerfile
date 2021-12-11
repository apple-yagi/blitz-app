FROM node:16.13.1-alpine AS deps

RUN apk add --no-cache libc6-compat curl && \
    curl -f https://pnpm.js.org/pnpm.js | node - add --global pnpm && \
    pnpm add -g pnpm

WORKDIR /usr/src

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile --prod

FROM node:16.13.1-alpine AS builder
RUN apk add --no-cache curl && \
    curl -f https://pnpm.js.org/pnpm.js | node - add --global pnpm && \
    pnpm add -g pnpm
WORKDIR /usr/src
COPY . .
COPY --from=deps /usr/src/node_modules ./node_modules
RUN pnpm build && pnpm install --production --ignore-scripts --prefer-offline

FROM node:16.13.1-alpine AS runner
WORKDIR /usr/src

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# You only need to copy next.config.js if you are NOT using the default configuration
# COPY --from=builder /app/next.config.js ./
COPY --from=builder /usr/src/public ./public
COPY --from=builder --chown=nextjs:nodejs /src/usr/.next ./.next
COPY --from=builder /usr/src/node_modules ./node_modules
COPY --from=builder /usr/src/package.json ./package.json

USER nextjs

EXPOSE 3000

ENV PORT 3000

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry.
# ENV NEXT_TELEMETRY_DISABLED 1

CMD ["node_modules/.bin/next", "start"]
