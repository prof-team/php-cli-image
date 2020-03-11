#!/bin/bash

set -e

# Disable xdebug
if [ -z "$XDEBUG_CONFIG" ]; then
    rm -f /usr/local/etc/php/conf.d/xdebug.ini
fi

if [ -f /custom-entrypoint.sh ]; then
    bash /custom-entrypoint.sh
fi

exec "$@"