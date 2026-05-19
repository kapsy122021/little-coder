FROM node:22-bookworm-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Normalize line endings for shebang scripts (handles Windows CRLF checkouts)
# and strip a possible UTF-8 BOM from docker.models.json so JSON.parse accepts it.
RUN sed -i 's/\r$//' bin/little-coder.mjs bin/update-check.mjs \
    && sed -i '1s/^\xEF\xBB\xBF//' docker.models.json \
    && chmod +x bin/little-coder.mjs \
    && ln -sf /app/bin/little-coder.mjs /usr/local/bin/little-coder
# Keep the agent container alive so users can `docker exec -it little-coder little-coder ...`.
# The little-coder binary is invoked on demand; no long-running server here.
ENTRYPOINT ["tail","-f","/dev/null"]
