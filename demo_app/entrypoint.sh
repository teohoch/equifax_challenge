#!/bin/bash
set -e
echo "Creating database if it doesn't exist and runing migrations"
rails db:migrate
rails db:seed

exec "$@"