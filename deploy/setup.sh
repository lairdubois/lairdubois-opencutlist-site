#!/usr/bin/env bash
# One-time server setup, run as root by `deploy/deploy.sh setup` ; safe to run again
# (existing user, Ruby, environment file and certificate are kept).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
domain=www.opencutlist.org
apex=opencutlist.org
home=/var/www/$domain
ruby=4.0.1

step() { printf '\n== %s\n' "$*"; }

step "Packages"
apt-get update -q
# Runtime : jemalloc, rsync (deploy), openssl (secret), curl (deploy check)
apt-get install -y -q git curl rsync libjemalloc2 openssl
# Build only (Ruby via ruby-build, native gem extensions)
apt-get install -y -q build-essential pkg-config libssl-dev libyaml-dev zlib1g-dev libffi-dev

step "User ocl-site ($home)"
id ocl-site >/dev/null 2>&1 || useradd --system --create-home --home-dir "$home" --shell /bin/bash ocl-site
chmod 755 "$home" # NGINX (www-data) reads app/public
install -d -o ocl-site -g ocl-site "$home/app"
cd "$home"

step "Ruby $ruby (rbenv, compiles for a few minutes the first time)"
# Explicit paths : sudo -i would escape a "~" in the command, leaving it unexpanded
rbenv_root=$home/.rbenv
sudo -u ocl-site env HOME="$home" RBENV_ROOT="$rbenv_root" bash -c "
  set -euo pipefail
  [ -d $rbenv_root ] || git clone -q --depth 1 https://github.com/rbenv/rbenv.git $rbenv_root
  [ -d $rbenv_root/plugins/ruby-build ] || git clone -q --depth 1 https://github.com/rbenv/ruby-build.git $rbenv_root/plugins/ruby-build
  git -C $rbenv_root/plugins/ruby-build pull -q
  $rbenv_root/bin/rbenv install --skip-existing $ruby
"
[ -x "$rbenv_root/versions/$ruby/bin/bundle" ] || { echo "Ruby $ruby missing in $rbenv_root/versions" >&2; exit 1; }

step "Environment /etc/ocl-site.env"
if [ -f /etc/ocl-site.env ]; then
  echo "kept"
else
  install -m 640 -o root -g ocl-site /dev/null /etc/ocl-site.env
  sed -e "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$(openssl rand -hex 64)|" "$here/ocl-site.env.example" > /etc/ocl-site.env
  echo "created, with a generated SECRET_KEY_BASE"
fi

step "systemd service"
install -m 644 "$here/ocl-site.service" /etc/systemd/system/ocl-site.service
systemctl daemon-reload
systemctl enable -q ocl-site

step "Rails command wrapper (sudo ocl-site-rails console)"
install -m 755 "$here/ocl-site-rails" /usr/local/bin/ocl-site-rails

step "Certificate $domain + $apex"
# Webroot : works without certbot's NGINX plugin ; renewals use the same challenge location
install -d -m 755 "$home/acme"
if [ -d "/etc/letsencrypt/live/$domain" ]; then
  echo "kept"
else
  # HTTP-only site first : the full one refers to the certificate files
  cat > "/etc/nginx/sites-available/$domain" <<NGINX
server {
  listen 80;
  listen [::]:80;
  server_name $domain $apex;
  location /.well-known/acme-challenge/ { root $home/acme; }
}
NGINX
  ln -sf "../sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
  nginx -t
  systemctl reload nginx
  certbot certonly --webroot -w "$home/acme" -d "$domain" -d "$apex" --cert-name "$domain" --deploy-hook "systemctl reload nginx"
fi

step "NGINX site"
install -m 644 "$here/nginx.conf" "/etc/nginx/sites-available/$domain"
ln -sf "../sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
nginx -t
systemctl reload nginx
