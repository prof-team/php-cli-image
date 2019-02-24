#!/bin/bash

set -e

if [ -f /custom-entrypoint.sh ]; then
    bash /custom-entrypoint.sh
fi

exec "$@"