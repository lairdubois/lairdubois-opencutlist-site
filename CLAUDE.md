# opencutlist.org — notes for Claude

See `README.md` for setup, pages and deployment.

- Rails 8.1, Ruby 4.0.1, no Active Record (`--skip-active-record`) : nothing is stored. Production cache is
  `:memory_store` (single Puma process), only for the Open Collective stats.
- Content : `config/site.yml` (releases, links, campaign, episodes ; read through `Site`) and
  `config/locales/en.yml` / `fr.yml` (all texts, kept in sync key for key). English is the default locale.
- `OpenCollective.stats` : GraphQL `stats.balance` (current balance, no start date) + `contributorsCount` of the
  collective `lairdubois-opencutlist-sketchup-extension` (currency USD, so `money` always shows `$`). Nil on any
  failure → no gauge. The gauge shows the balance as a % of `campaign.goal`.
- Episodes : only released ones + the next one are shown on `/lab` (`Site.visible_episodes`).
- Tests stub the network : `with_campaign(stats)` (test_helper), `Net::HTTP.stub_start_with` (open_collective_test).
- Responsive from 320 px : big titles use `.display-1/2/3` (fluid `clamp` sizes, no hyphenation : the longest
  French words must fit whole), `.btn` goes full width under 40rem, the header nav moves to its own row under `md`.
  After a layout or text change : `python3 script/responsive_audit.py http://127.0.0.1:<port>` (no overflow at
  320 → 1280 px, `--shots DIR` for screenshots).
- French texts : non-breaking space (U+00A0) before `: ; ? !`, or the sign wraps alone to the next line.
- Tailwind sources are explicit (`source(none)` + `@source`) : the deployed copy has no `.git`.
- Fonts in `app/assets/fonts` come from ocl-video (`assets/`) : Lexend Exa (`display.woff2`), Lexend
  (`text.woff2`), monofur subset to Latin-1 (`mono.woff`, from `mono.ttf` with pyftsubset). Smart tool icons in
  `app/assets/images/smart/` are the extension's `icon-smart-*.svg`.
- Production : Debian 12 next to L'Air du Bois and localize, user `ocl-site`, port 3008, `deploy/`.

## Content rules (campaign)

- Always "OpenCutList" (camel case) ; never "OCL" in texts, never all caps. `.display` and `.label` are
  uppercased by CSS (buttons are not : Lexend, normal case, like the header nav) : any text shown there goes through `brand(…)`, which keeps "OpenCutList" in a `normal-case`
  span (guarded by the "camel case" test in `pages_test.rb`).
- Never "free" / "gratuit" (nor "libre" for the licence) : say "open source" and "crowdfunded" /
  "financement participatif", "funded by its users" / "financé par ses utilisateurs".
- "LAB version" / "version LAB" : the most advanced build, updated continuously. Never "beta" nor "bug" : we
  invite feedback and ideas.
- Charte (ocl-video `templates/charte.css`) : orange `#f77f00`, dark `#3e3b33`, pink `#e84fa9` for the LAB pill, the
  "Support" header link, the campaign gauge bar and the "Contribute on Open Collective" button only (`.btn-lab`, darker `#c93a8c` on hover) ; square corners.

## Hard rules

- Don't deploy without an explicit request.
