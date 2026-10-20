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

## Production

One Puma process on `127.0.0.1:3008` behind NGINX, on the same server as OpenCutList Localize. First
install, updates, overrides without a deploy, logs : see [`deploy/README.md`](deploy/README.md).

    DEPLOY_HOST=you@<server> deploy/deploy.sh          # update (first time : deploy/deploy.sh setup)

## License

GNU General Public License v3.0, like OpenCutList.
