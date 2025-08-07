# Use the official Playwright image as a base
FROM mcr.microsoft.com/playwright:v1.44.0-jammy

# Set working directory
WORKDIR /app

# Install VNC and other utilities
USER root
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    && rm -rf /var/lib/apt/lists/*
USER pwuser

# Copy application files
COPY package.json .
RUN npm install

COPY server.js .
COPY start.sh .

# Make the start script executable
RUN chmod +x /app/start.sh

# Expose ports for the API and VNC
EXPOSE 3000
EXPOSE 7900

# Start the services
CMD ["/app/start.sh"]
