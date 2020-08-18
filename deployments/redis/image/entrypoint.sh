#!/bin/sh
set -e

case "$REDIS_ROLE" in
    master|replica)
        ;;
    sentinel)
        echo "$SENTINEL_CONFIG_CONTENT" >"$SENTINEL_CONFIG_FILE"
        ;;
    *)
        echo "invalid REDIS_ROLE '${REDIS_ROLE}'"
esac

exec /usr/local/bin/docker-entrypoint.sh "$@"
