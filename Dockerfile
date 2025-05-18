# Stage 1: Build the application
FROM node:20 AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

RUN npm run build

# Stage 2: Run the application
FROM node:20

WORKDIR /app

COPY --from=builder /app/build ./build
COPY .env* ./

RUN npm install --production

EXPOSE 3000

CMD ["npm", "start"]
