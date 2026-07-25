# Stage 1: Build the React application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code
COPY . .

# Build the application for production
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:alpine

# Copy the built application from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Remove the default Nginx configuration template
RUN rm /etc/nginx/templates/default.conf.template

# Create a new Nginx configuration template that uses the PORT environment variable.
# The official Nginx image's entrypoint processes templates in /etc/nginx/templates
# and substitutes environment variables like $PORT.
RUN echo "server {" > /etc/nginx/templates/default.conf.template \
    && echo "    listen ${PORT:-8080};" >> /etc/nginx/templates/default.conf.template \
    && echo "    listen [::]:${PORT:-8080};" >> /etc/nginx/templates/default.conf.template \
    && echo "    server_name  localhost;" >> /etc/nginx/templates/default.conf.template \
    && echo "" >> /etc/nginx/templates/default.conf.template \
    && echo "    location / {" >> /etc/nginx/templates/default.conf.template \
    && echo "        root   /usr/share/nginx/html;" >> /etc/nginx/templates/default.conf.template \
    && echo "        index  index.html index.htm;" >> /etc/nginx/templates/default.conf.template \
    && echo "        try_files \$uri \$uri/ /index.html;" >> /etc/nginx/templates/default.conf.template \
    && echo "    }" >> /etc/nginx/templates/default.conf.template \
    && echo "" >> /etc/nginx/templates/default.conf.template \
    && echo "    error_page   500 502 503 504  /50x.html;" >> /etc/nginx/templates/default.conf.template \
    && echo "    location = /50x.html {" >> /etc/nginx/templates/default.conf.template \
    && echo "        root   /usr/share/nginx/html;" >> /etc/nginx/templates/default.conf.template \
    && echo "    }" >> /etc/nginx/templates/default.conf.template \
    && echo "}" >> /etc/nginx/templates/default.conf.template

# Set default port and expose it
ENV PORT 8080
EXPOSE 8080

# Nginx will be started by its default CMD, which processes the template and runs Nginx.
