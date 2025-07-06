FROM oven/bun:1.2.18

WORKDIR /app
COPY package*.json bun.lockb* ./
RUN bun install
COPY . .
EXPOSE 5432
CMD ["bun", "run", "index.ts"]
