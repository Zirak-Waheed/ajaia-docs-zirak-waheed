#!/usr/bin/env bash
# Render build: install, compile assets, migrate, seed demo accounts (idempotent).
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:migrate
bin/rails db:seed
