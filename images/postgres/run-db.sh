#!/bin/bash
set -e

# Sökvägar för Postgres-binärer
export PATH="$PATH:/usr/pgsql-16/bin"

# 1. SJÄLVLÄKNING: Städa trasig PVC om PG_VERSION saknas
if [ -d "$PGDATA" ] && [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "--- Found incomplete data at $PGDATA. Cleaning up for fresh init... ---"
    rm -rf "${PGDATA:?}"/*
fi

# 2. INITIERING: Om mappen är tom, skapa databasklustret
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "--- Initializing fresh database cluster ---"
    initdb --username=postgres -D "$PGDATA"
    
    # 3. KONFIGURATION
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    # 4. TEMPORÄR START: För att skapa din app-användare och databas
    echo "--- Starting temporary server for initial setup ---"
    pg_ctl -D "$PGDATA" -w start
    sleep 2

    echo "--- Creating user and database from environment variables ---"
    psql --username "postgres" --dbname "postgres" <<-EOSQL
        CREATE USER ${POSTGRESQL_USER} WITH PASSWORD '${POSTGRESQL_PASSWORD}';
        CREATE DATABASE "${POSTGRESQL_DATABASE}" OWNER ${POSTGRESQL_USER};
        GRANT ALL PRIVILEGES ON DATABASE "${POSTGRESQL_DATABASE}" TO ${POSTGRESQL_USER};
        \c "${POSTGRESQL_DATABASE}"
        GRANT ALL ON SCHEMA public TO ${POSTGRESQL_USER};
EOSQL
    
    echo "--- Setup complete. Stopping temporary server ---"
    pg_ctl -D "$PGDATA" -m fast -w stop
fi

# 5. START: Kör Postgres som huvudprocess (PID 1)
echo "--- Starting PostgreSQL ---"
exec postgres -D "$PGDATA"