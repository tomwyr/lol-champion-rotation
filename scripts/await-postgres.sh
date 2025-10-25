#!/bin/sh

attempts=10

echo "Waiting for PostgreSQL to be ready ..."

for i in $(seq 1 $attempts); do
  if pg_isready -d "$DATABASE_URL"; then
    break
  fi

  if [ $i -eq $attempts ]; then
    echo "PostgreSQL not ready after $attempts attempts"
    exit 1
  fi

  sleep 1
done
