# Deployment (Debian 12, NGINX, systemd)

The site runs as one Puma process on `127.0.0.1:3008`, behind the server's existing NGINX (next to
L'Air du Bois and OpenCutList Localize), at `https://www.opencutlist.org`. `opencutlist.org` redirects to
`www.opencutlist.org`. Nothing is stored : no database, the only cache (Open Collective stats, 15 min) is
in memory and starts empty after each restart.

    /var/www/www.opencutlist.org/   home of the ocl-site system user
      .rbenv/                       Ruby 4.0.1
      app/                          the code (deploy/deploy.sh), NGINX serves app/public
      acme/                         Let's Encrypt challenges (certbot webroot)
    /etc/ocl-site.env               environment (SECRET_KEY_BASE, overrides of config/site.yml)

## Prerequisites

- DNS : `www.opencutlist.org` and `opencutlist.org` → the server (one certificate for both is requested
  during the setup).
- An SSH account with sudo on the server, and `rsync` there (`sudo apt install rsync` if missing).
- certbot (webroot mode : its NGINX plugin is not needed).
- Port 3008 free (3007 is OpenCutList Localize).

## First install

From the dev machine :

    DEPLOY_HOST=you@<server> deploy/deploy.sh setup

It uploads the code to `~/ocl-site-deploy` on the server (no secrets : `.env*` and `config/*.key` are
excluded), then, with sudo (one password prompt), runs `deploy/setup.sh` and `deploy/remote.sh`.

`deploy/setup.sh` (safe to run again, keeps what already exists) :
- apt packages : runtime ones (git, curl, rsync, jemalloc, openssl) and build ones for Ruby and native
  gems (build-essential, pkg-config, libssl / libyaml / zlib / libffi `-dev`)
- the `ocl-site` system user, home `/var/www/www.opencutlist.org`
- Ruby 4.0.1 through rbenv (compiles for a few minutes the first time)
- `/etc/ocl-site.env` from `ocl-site.env.example`, with a generated `SECRET_KEY_BASE` (an existing file
  is kept)
- the systemd service, the `ocl-site-rails` wrapper in `/usr/local/bin`
- the certificate for `www.opencutlist.org` + `opencutlist.org` (certbot webroot, first time only : an
  HTTP-only site serves the challenge from `acme/`) and the NGINX site, then `nginx -t` and reload

`deploy/remote.sh` : copy into `app/`, gems, assets (Tailwind + Propshaft), restart, `/up` check.

## Updates

    DEPLOY_HOST=you@<server> deploy/deploy.sh

It ships the working tree as it is (uncommitted changes included). `setup` again is harmless : it keeps
the user, Ruby, environment and certificate.

## Changing the downloads without a deploy

`config/site.yml` reads three overrides from `/etc/ocl-site.env` :

- `SITE_LAB_URL` : the LAB `.rbz` download link
- `SITE_LAB_BUILD` : the LAB build shown next to it
- `SITE_STABLE_URL` : the stable version's link (Extension Warehouse)

Edit the file (`sudo nano /etc/ocl-site.env`), then `sudo systemctl restart ocl-site`. Any other content
(texts, releases, episodes, campaign) goes through a deploy.

## Running commands on the server

    sudo ocl-site-rails console     # or any bin/rails task, as ocl-site with the production environment

## Logs

- `journalctl -u ocl-site -f` (Rails logs to stdout)
- NGINX : `/var/log/nginx/access.log` and `error.log`
- Service status : `systemctl status ocl-site` ; the health check : `curl -I http://127.0.0.1:3008/up`
