#!/bin/bash
set -e

# 1. SÖKVÄGAR
export PATH="$PATH:/usr/pgsql-16/bin"
# PGDATA är redan satt till .../userdata i Dockerfile

# 2. SIGNALHANTERING
trap "echo 'Stopping database...'; pg_ctl -D \"$PGDATA\" stop -m fast; exit 0" SIGTERM SIGINT

# 3. INITIERING
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing database..."
    
    # FIX: Vi lägger till --username=postgres här!
    # Detta tvingar superusern att heta 'postgres' oavsett vem vi är.
    initdb --username=postgres -D "$PGDATA"

    # 4. KONFIGURATION
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "logging_collector = off" >> "$PGDATA/postgresql.conf"
    echo "log_destination = 'stderr'" >> "$PGDATA/postgresql.conf"
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"
    echo "host all all ::0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    # 5. SKAPA ANVÄNDARE
    echo "Starting temporary server..."
    pg_ctl -D "$PGDATA" -w start

    echo "Creating user ${POSTGRESQL_USER}..."
    psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
        CREATE USER ${POSTGRESQL_USER} WITH PASSWORD '${POSTGRESQL_PASSWORD}';
        CREATE DATABASE ${POSTGRESQL_DATABASE};
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRESQL_DATABASE} TO ${POSTGRESQL_USER};
        \c ${POSTGRESQL_DATABASE}
        GRANT ALL ON SCHEMA public TO ${POSTGRESQL_USER};
EOSQL
    
    echo "Stopping temporary server..."
    pg_ctl -D "$PGDATA" -m fast -w stop
fi

# 6. START
echo "Starting PostgreSQL..."
exec postgres -D "$PGDATA"