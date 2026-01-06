#!/bin/bash
set -e
export PATH="$PATH:/usr/pgsql-16/bin"

# 1. SJÄLVLÄKNING (Städa om installationen avbrutits)
if [ -d "$PGDATA" ] && [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "--- Found incomplete data. Cleaning up for fresh init... ---"
    rm -rf "${PGDATA:?}"/*
fi

# 2. FULL INITIERING
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "--- Initializing database ---"
    initdb --username=postgres -D "$PGDATA"
    
    echo "--- Applying chmod 700 fix ---"
    chmod 700 "$PGDATA"

    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    echo "--- Starting temporary server for setup ---"
    pg_ctl -D "$PGDATA" -w start
    sleep 2

    echo "--- Creating user and database ---"
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

# 3. STARTA PÅ RIKTIGT
echo "--- Final Permission Check ---"
chmod 700 "$PGDATA"
echo "--- Starting PostgreSQL ---"
exec postgres -D "$PGDATA"