#!/bin/bash

set -e

# Disable xdebug
if [ -z "$XDEBUG_CONFIG" ]; then
    rm -f /usr/local/etc/php/conf.d/xdebug.ini
fi

if [ -n "$INI_MEMORY_LIMIT" ]; then
    sed -i "s/memory_limit.*/memory_limit=$INI_MEMORY_LIMIT/" /usr/local/etc/php/conf.d/common.ini
fi

if [ -f /custom-entrypoint.sh ]; then
    bash /custom-entrypoint.sh
fi

exec "$@"
