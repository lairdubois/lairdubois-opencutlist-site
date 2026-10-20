#!/usr/bin/env bash
# Server side of deploy/deploy.sh, run as root : sudo bash remote.sh <uploaded tree>
set -euo pipefail

src="${1:?uploaded tree}"
home=/var/www/www.opencutlist.org
app=$home/app
[ -f /etc/ocl-site.env ] || { echo "server not set up : deploy/deploy.sh setup" >&2; exit 1; }
[ -x "$home/.rbenv/versions/4.0.1/bin/bundle" ] || { echo "Ruby 4.0.1 missing : deploy/deploy.sh setup" >&2; exit 1; }

# What only exists on the server (logs, builds, gems) is excluded, hence kept by --delete.
# a+rX : NGINX (www-data) must read public/ and the precompiled assets, whatever the local file modes
rsync -a --delete --chown=ocl-site:ocl-site --chmod=a+rX \
  --exclude /log/ --exclude /tmp/ \
  --exclude /public/assets/ --exclude /app/assets/builds/ --exclude /vendor/bundle/ --exclude /.bundle/ \
  "$src/" "$app/"

cd "$app"
sudo -u ocl-site bash -c "
  set -euo pipefail
  set -a; source /etc/ocl-site.env; set +a
  export PATH=$home/.rbenv/versions/4.0.1/bin:\$PATH
  mkdir -p log tmp
  # Propshaft only adds the app/assets/* directories that exist at boot : the Tailwind build goes here
  mkdir -p app/assets/builds
  bundle config set --local deployment true
  bundle config set --local without development:test
  bundle install --quiet
  bin/rails assets:precompile
  # Propshaft keeps an existing digest file as is : fixes assets compiled from an unreadable source
  chmod -R a+rX public/assets
"

systemctl restart ocl-site
for _ in $(seq 1 20); do
  curl -fsS -o /dev/null http://127.0.0.1:3008/up 2>/dev/null && { echo "up"; exit 0; }
  sleep 1
done
echo "not answering on /up : journalctl -u ocl-site -n 50" >&2
exit 1
