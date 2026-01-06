#!/bin/bash
echo "--- REDIS HEALTH CHECK ---"

# Testa ping
PING_RES=$(redis-cli -a $REDIS_PASSWORD ping 2>/dev/null)

if [ "$PING_RES" == "PONG" ]; then
    echo "✅ Connection: OK (Received PONG)"
else
    echo "❌ Connection: FAILED (Check password/service)"
    exit 1
fi

# Testa skrivning/läsning
redis-cli -a $REDIS_PASSWORD set health-test "alive" > /dev/null
CHECK_VAL=$(redis-cli -a $REDIS_PASSWORD get health-test)

if [ "$CHECK_VAL" == "alive" ]; then
    echo "✅ Data Integrity: OK (Set/Get works)"
else
    echo "❌ Data Integrity: FAILED"
    exit 1
fi

echo "--------------------------"
echo "Result: REDIS IS HEALTHY"