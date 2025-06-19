# Use Node.js base image
FROM node:20-alpine
LABEL authors="naporastudio"

# Install dependencies only once
RUN apk add --no-cache curl && corepack enable

# Set working directory
WORKDIR /usr/src/app

# Copy dependency files first to leverage Docker caching
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Install dependencies based on the lock file available
RUN \
    if [ -f yarn.lock ]; then yarn install --immutable; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then pnpm i --frozen-lockfile; \
    else echo "Lockfile not found." && exit 1; \
    fi

# Copy the rest of the application files (to avoid re-triggering dependency install step unnecessarily)
COPY . .

# Build the Medusa application
RUN \
    if [ -f yarn.lock ]; then yarn build; \
    elif [ -f package-lock.json ]; then npm run build; \
    elif [ -f pnpm-lock.yaml ]; then pnpm run build; \
    else echo "Lockfile not found." && exit 1; \
    fi

# Install Medusa dependencies
WORKDIR /usr/src/app/.medusa/server
# RUN npm install

# Expose default Medusa port
EXPOSE 9000

# Command to run in production
CMD ["sh", "-c", "npm run start"]