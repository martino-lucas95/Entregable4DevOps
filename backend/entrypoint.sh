#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Check if migrations directory exists and has files
if [ -d ./prisma/migrations ] && [ "$(ls -A ./prisma/migrations 2>/dev/null)" ]; then
    echo "Running migrations..."
    npx prisma migrate deploy --schema=./prisma/schema.prisma
else
    echo "Pushing database schema..."
    npx prisma db push --schema=./prisma/schema.prisma --accept-data-loss
fi

# Start the application
echo "Starting application..."
exec node dist/main.js
