#!/bin/bash
set -e

# Sökväg för data
export REDIS_DATA="/var/lib/redis/data"

# Signalhantering (Graceful shutdown)
trap "echo 'Stopping Redis...'; redis-cli shutdown; exit 0" SIGTERM SIGINT

# Skapa config om den saknas
if [ ! -f "/etc/redis.conf" ]; then
    echo "Generating redis.conf..."
    
    # 1. Lyssna på alla IP-adresser (Krävs för OpenShift)
    echo "bind 0.0.0.0" > /etc/redis.conf
    
    # 2. Stäng av protected mode (Vi litar på OpenShifts nätverksregler)
    echo "protected-mode no" >> /etc/redis.conf
    
    # 3. Spara data till disken (Persistens)
    echo "dir $REDIS_DATA" >> /etc/redis.conf
    
    # 4. Logga till stdout
    echo "logfile \"\"" >> /etc/redis.conf
    
    # 5. Sätt lösenord om variabeln finns
    if [ -n "$REDIS_PASSWORD" ]; then
        echo "requirepass $REDIS_PASSWORD" >> /etc/redis.conf
    fi
fi

echo "Starting Redis Server..."
redis-server /etc/redis.conf
