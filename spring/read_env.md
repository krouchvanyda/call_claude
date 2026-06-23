# ===========================================================================
# Copy to .env and edit before running docker-compose or `gradle bootRun`.
# Required production swaps marked with [REQUIRED].
# ===========================================================================

# --- Database ---
DB_URL=jdbc:postgresql://localhost:5432/erp
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_POOL_SIZE=10

# --- Server ---
SERVER_PORT=8080
SERVER_CONTEXT_PATH=/

# --- JWT [REQUIRED in non-local environments] ---
# Generate a long random secret (>= 64 chars). Example:
#   openssl rand -base64 64
JWT_ISSUER=erp
JWT_SECRET=dev-secret-change-me-in-production-must-be-long-enough-for-hmac-sha256
JWT_ACCESS_TTL=P365D
JWT_REFRESH_TTL=P365D

# --- CORS ---
# Comma-separated list, e.g. https://app.example.com,https://admin.example.com
CORS_ALLOWED_HOSTS=*

# --- Rate limit (Bucket4j, per-IP, in-memory) ---
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=120
AUTH_RATE_LIMIT_PER_MINUTE=20

# --- Stream Video (server-side token mint) ---
STREAM_API_KEY=4jgpsany48vw
STREAM_API_SECRET=dahx3mgg5pcpyg4m8kwtre5yvy7f2rsv9zca38na9a4jenwza8sac49pcunk72pf
STREAM_TOKEN_TTL_MINUTES=60

# --- Firebase Cloud Messaging (incoming-call push) ---
FCM_ENABLED=false
FCM_SERVICE_ACCOUNT_JSON_PATH=/secrets/firebase-sa.json

# --- Uploads ---
UPLOAD_MAX_FILE_SIZE=25MB
UPLOAD_MAX_REQUEST_SIZE=30MB
