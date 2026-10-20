# opencutlist.org

The OpenCutList website, at `https://www.opencutlist.org` : downloads (7.1 stable from the SketchUp
Extension Warehouse, 8 LAB as a `.rbz`), the OpenCutList 8 LAB campaign and how the project is funded.

Rails 8.1, no database : content is in views + `config/locales/{en,fr}.yml`, releases, links, campaign
and episodes in `config/site.yml`. The campaign gauge reads the Open Collective GraphQL API (cached 15 min
in memory, hidden if the API fails).

## Development

    bundle install
    bin/dev                 # http://localhost:3000 (Rails + Tailwind watch)
    bin/rails test
    bin/rubocop && bin/brakeman

## Pages

| Path | |
|---|---|
| `/`, `/lab`, `/download`, `/support` | Redirect to `/en/…` or `/fr/…` from `Accept-Language` (campaign short links) |
| `/:locale` | Home |
| `/:locale/lab` | OpenCutList 8 LAB : download, install, feedback, episodes, gauge |
| `/:locale/download` | Stable and LAB downloads |
| `/:locale/support` | Funding, gauge, other ways to help |

## Updating content

- New LAB build, new stable version, episode online (`url:`), L'Air du Bois thread, YouTube channel :
  `config/site.yml`, then deploy.
- Without a deploy : `SITE_LAB_URL`, `SITE_LAB_BUILD`, `SITE_STABLE_URL` in
  `/etc/ocl-site.env`, then `sudo systemctl restart ocl-site`.

## Production (Debian 12, NGINX, systemd)

Same layout as OpenCutList Localize, on the same server : one Puma process on `127.0.0.1:3008` behind NGINX.

    /var/www/www.opencutlist.org/   home of the ocl-site system user
      .rbenv/                       Ruby 4.0.1
      app/                          the code, NGINX serves app/public
      acme/                         Let's Encrypt challenges (certbot webroot)
    /etc/ocl-site.env               environment (SECRET_KEY_BASE, overrides)

Prerequisites : DNS `www.opencutlist.org` and `opencutlist.org` → the server, certbot, an SSH account with
sudo, port 3008 free.

First install (packages, user, Ruby, environment, service, certificate for www + apex, NGINX site, then deploy) :

    DEPLOY_HOST=you@<server> deploy/deploy.sh setup

Updates :

    DEPLOY_HOST=you@<server> deploy/deploy.sh

`opencutlist.org` redirects to `www.opencutlist.org`. Logs : `journalctl -u ocl-site -f`. Console :
`sudo ocl-site-rails console`.

## License

GNU General Public License v3.0, like OpenCutList.
