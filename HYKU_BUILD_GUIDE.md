# Hyku Build & Testing Guide with Stack Car

---

## wvu_knapsack: Local Smoke Testing & VM Production Deployment

This section covers the standalone production stack (`docker-compose.production.yml`) used for local smoke-testing and VM deployment. It does **not** use Stack Car. See the rest of this file for standard Hyku dev workflow with Stack Car.

---

### Architecture Overview

```
wvu_knapsack/                   ← this repo (knapsack engine)
└── hyrax-webapp/               ← git submodule (Hyku core, do not edit)
    └── config/                 ← base Rails config (overridden by knapsack)
docker-compose.production.yml   ← standalone production compose (no extends)
.env.production                 ← gitignored, single source of env for compose
.env.production.example         ← committed template
scripts/setup.sh                ← one-time idempotent setup script
startup-solr.sh                 ← custom Solr SolrCloud startup
solr-setup/security.json        ← Solr ZooKeeper security config
```

**Services:** `zoo` (ZooKeeper) → `solr` (SolrCloud 8.3.1) → `fcrepo`, `db`, `redis` → `initialize_app` → `worker` + `web`

All data is stored in `./data/*` bind mounts — no named Docker volumes.

---

### Part 1: Local Production Smoke Testing (Developer Machine)

Use this to validate a build locally before deploying to the VM.

#### Prerequisites

- Docker Desktop running
- No Stack Car proxy needed (different port 3000, no Traefik)
- `lvh.me` for wildcard DNS: `*.lvh.me` resolves to `127.0.0.1` with no HSTS

#### Step 1: Create `.env.production`

```bash
cp .env.production.example .env.production
```

Edit `.env.production` with these local values:

```env
# Routing — use lvh.me (wildcard → 127.0.0.1, no HSTS, safe for HTTP)
HYKU_ROOT_HOST=lvh.me
HYKU_ADMIN_HOST=admin-wvu-knapsack.lvh.me
HYKU_DEFAULT_HOST=%{tenant}-wvu-knapsack.lvh.me
HYKU_EXTRA_HOSTS=.lvh.me

# Allow plain HTTP (no SSL proxy locally)
DISABLE_FORCE_SSL=true

# Generate a real secret or use a placeholder for smoke-testing only
SECRET_KEY_BASE=changeme_generate_with_rails_secret

# Admin credentials to seed
INITIAL_ADMIN_EMAIL=admin@example.com
INITIAL_ADMIN_PASSWORD=changeme
```

Leave everything else at the example defaults for local testing.

> **Why lvh.me?** `localhost.direct` (which Stack Car uses) is registered under HSTS preload, so browsers force HTTPS even on port 3000. `lvh.me` has no HSTS and works with plain HTTP.

> **APP_NAME convention:** must use hyphens (`wvu-knapsack`), not underscores. Underscores are not valid in DNS hostname labels and Rails 7.2 `HostAuthorization` rejects them before consulting the allowed list.

#### Step 2: Build the image

```bash
docker-compose -f docker-compose.production.yml build
```

#### Step 3: Start the stack

```bash
docker-compose -f docker-compose.production.yml up -d
```

Watch initialization complete (Solr configset upload, DB seed, bundle install):

```bash
docker-compose -f docker-compose.production.yml logs -f initialize_app
```

Wait for web to be ready:

```bash
docker-compose -f docker-compose.production.yml logs -f web | grep "Listening on"
```

#### Step 4: Precompile assets (first run only)

Assets are not precompiled during `docker build` for the production target. Run once after the stack is up:

```bash
docker-compose -f docker-compose.production.yml exec web bundle exec rails assets:precompile
```

Assets are stored in `./data/assets/` (bind-mounted), so this survives container recreation.

> **Why needed:** Rails production mode does not serve `public/assets` via Puma unless `RAILS_SERVE_STATIC_FILES=true` is set **and** the assets have been precompiled. Both are required.

#### Step 5: Run one-time setup

```bash
docker-compose -f docker-compose.production.yml exec web sh /app/samvera/scripts/setup.sh
```

This script is idempotent and safe to re-run. It:
1. Creates and migrates the database (detects existing tables, runs `db:migrate` vs `db:schema:load`)
2. Seeds the database (creates superadmin from `INITIAL_ADMIN_EMAIL`/`INITIAL_ADMIN_PASSWORD`)
3. Optionally creates first repository tenant from `HYKU_FIRST_TENANT_NAME`/`HYKU_FIRST_TENANT_CNAME`

#### Step 6: Test in browser

- Admin interface: `http://admin-wvu-knapsack.lvh.me:3000`
- Sign in: `http://admin-wvu-knapsack.lvh.me:3000/users/sign_in`
- Credentials: `INITIAL_ADMIN_EMAIL` / `INITIAL_ADMIN_PASSWORD`

> **CSRF / login note:** The session cookie requires `DISABLE_FORCE_SSL=true` AND `config/initializers/session_store_override.rb` (committed). Without it, hyrax-webapp sets `secure: true` on the session cookie, browsers refuse to send it over HTTP, and every login attempt fails with "change rejected" (422 CSRF failure).

#### Updating env vars

Always use `up -d` (not `restart`) when `.env.production` changes — `restart` reuses the cached env:

```bash
docker-compose -f docker-compose.production.yml up -d --no-deps web worker
```

#### Stopping / cleaning up

```bash
# Stop without removing data
docker-compose -f docker-compose.production.yml down

# Full reset including all data
docker-compose -f docker-compose.production.yml down
rm -rf ./data
```

---

### Part 2: VM Production Deployment (DevOps Handoff)

#### Prerequisites

- VM running Ubuntu LTS with Docker + Docker Compose installed
- DNS configured: `admin-wvu-knapsack.lib.wvu.edu` and `*.lib.wvu.edu` pointing to VM IP
- SSL-terminating reverse proxy (Nginx/Traefik) in front, forwarding HTTP to port 3000
- Port 3000 not exposed publicly — only proxy talks to it

#### Step 1: Clone the repo with submodules

```bash
git clone --recurse-submodules https://github.com/wvulibraries/wvu_knapsack.git
cd wvu_knapsack
```

Or if already cloned:

```bash
git submodule update --init --recursive
```

#### Step 2: Create `.env.production`

```bash
cp .env.production.example .env.production
nano .env.production   # or vim
```

Required changes from the example:

| Variable | VM Value |
|---|---|
| `SECRET_KEY_BASE` | Output of `openssl rand -hex 64` |
| `NEGATIVE_CAPTCHA_SECRET` | Output of `openssl rand -hex 32` |
| `DB_PASSWORD` | Strong random password |
| `HYKU_ROOT_HOST` | `lib.wvu.edu` |
| `HYKU_ADMIN_HOST` | `admin-wvu-knapsack.lib.wvu.edu` |
| `HYKU_DEFAULT_HOST` | `%{tenant}-wvu-knapsack.lib.wvu.edu` |
| `INITIAL_ADMIN_EMAIL` | Real admin email |
| `INITIAL_ADMIN_PASSWORD` | Strong password |
| `RAILS_SERVE_STATIC_FILES` | `true` (unless Nginx serves `/assets` directly) |

**Remove or leave commented out:**
- `DISABLE_FORCE_SSL` — leave unset; the SSL proxy handles HTTPS, Rails receives plain HTTP internally
- `HYKU_EXTRA_HOSTS` — not needed; `.lib.wvu.edu` is already in `host_authorization.rb`

Generate secrets:

```bash
openssl rand -hex 64   # → SECRET_KEY_BASE
openssl rand -hex 32   # → NEGATIVE_CAPTCHA_SECRET
```

#### Step 3: Build the image

```bash
docker-compose -f docker-compose.production.yml build
```

Or pull pre-built from GHCR if CI publishes it:

```bash
docker-compose -f docker-compose.production.yml pull
```

#### Step 4: Start the stack

```bash
docker-compose -f docker-compose.production.yml up -d
```

Watch the initialization sequence:

```bash
# ZooKeeper and Solr (wait for "SolrCloud mode" in solr logs)
docker-compose -f docker-compose.production.yml logs -f zoo solr

# App initialization (DB migrate/seed, Solr configset upload — ~2-3 min)
docker-compose -f docker-compose.production.yml logs -f initialize_app

# Web (wait for "Listening on http://0.0.0.0:3000")
docker-compose -f docker-compose.production.yml logs -f web
```

#### Step 5: Precompile assets

```bash
docker-compose -f docker-compose.production.yml exec web bundle exec rails assets:precompile
```

Stored in `./data/assets/` — only needs to be run once per build (or after gem/asset changes).

#### Step 6: Run one-time setup

```bash
docker-compose -f docker-compose.production.yml exec web sh /app/samvera/scripts/setup.sh
```

This is idempotent — safe to re-run on updates.

To pre-create the first repository tenant (optional — can also do via admin UI):

```bash
# Add to .env.production before running setup:
HYKU_FIRST_TENANT_NAME=wvu
HYKU_FIRST_TENANT_CNAME=wvu-wvu-knapsack.lib.wvu.edu
```

> **Admin host is not a tenant.** `HYKU_ADMIN_HOST` (`admin-wvu-knapsack.lib.wvu.edu`) routes to the superadmin interface — do not try to create an `Account` record for it. Hyku reserves the admin cname and it will fail with "Domain names cname is reserved."

#### Step 7: Configure the reverse proxy

The app listens on port 3000 (HTTP). Example Nginx config:

```nginx
server {
    listen 443 ssl;
    server_name admin-wvu-knapsack.lib.wvu.edu *.lib.wvu.edu;

    ssl_certificate     /etc/ssl/certs/lib.wvu.edu.crt;
    ssl_certificate_key /etc/ssl/private/lib.wvu.edu.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

`X-Forwarded-Proto: https` tells Rails it's behind SSL so `force_ssl` redirect loop doesn't occur.

#### Step 8: Verify

```bash
# All 7 containers should be Up
docker-compose -f docker-compose.production.yml ps

# Check Solr is in SolrCloud mode with collections
curl -s http://solr:SolrRocks@localhost:8983/solr/admin/collections?action=LIST

# Test admin URL
curl -si https://admin-wvu-knapsack.lib.wvu.edu/users/sign_in | head -5
```

---

### Updating the Application (VM)

```bash
# Pull latest code + submodule
git pull && git submodule update --recursive

# Rebuild image
docker-compose -f docker-compose.production.yml build

# Recreate containers (reads updated env_file, not just restart)
docker-compose -f docker-compose.production.yml up -d

# Run migrations (setup.sh is idempotent)
docker-compose -f docker-compose.production.yml exec web sh /app/samvera/scripts/setup.sh

# Re-precompile if assets changed
docker-compose -f docker-compose.production.yml exec web bundle exec rails assets:precompile
```

> **`up -d` vs `restart`:** Always use `up -d` after code or `.env.production` changes. `docker-compose restart` reuses the cached environment and does NOT re-read `env_file`.

---

### Data Persistence

All state is in `./data/` bind mounts:

| Directory | Contents |
|---|---|
| `./data/db` | PostgreSQL database files |
| `./data/solr` | Solr index and core data |
| `./data/zoo` / `./data/zk` | ZooKeeper state |
| `./data/fcrepo` | Fedora repository objects |
| `./data/uploads` | User-uploaded files |
| `./data/assets` | Precompiled asset pipeline output |
| `./data/cache` | Rails tmp/cache |
| `./data/redis` | Redis persistence |
| `./data/logs/solr` | Solr logs |

Back up the entire `./data/` directory to preserve all application state.

---

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| 403 Blocked hosts | Host not in allowed list | Check `HYKU_ROOT_HOST`/`HYKU_ADMIN_HOST` match request; see `config/initializers/host_authorization.rb` |
| Login fails "change was rejected" (422) | CSRF token unverifiable — session cookie not sent | On HTTP: ensure `DISABLE_FORCE_SSL=true` is set (enables `session_store_override.rb` to drop `Secure` flag) |
| Pages load with no CSS | Assets not precompiled or `RAILS_SERVE_STATIC_FILES` not set | Run `assets:precompile`; set `RAILS_SERVE_STATIC_FILES=true` |
| Solr not in SolrCloud mode | Using wrong startup command | `startup-solr.sh` uses `solr start -f -c -z zoo:2181` — check logs |
| `solr.xml does not exist` | Fresh bind mount, no solr.xml | `startup-solr.sh` seeds it from `/opt/solr/server/solr/solr.xml` automatically |
| DB `ProtectedEnvironmentError` | Tried `db:schema:load` on existing DB | `setup.sh` detects table count and uses `db:migrate` instead |
| "Domain names cname is reserved" | Tried to create Account for admin host | Admin host is not a tenant — use admin UI to create repository tenants |
| `restart` doesn't pick up new env | `restart` reuses cached env | Use `docker-compose up -d` to recreate containers |
| Bundle install slow on every start | No gem cache volume | Expected — gems install to container-local paths; use pre-built GHCR image on VM |

---

## ⚠️ Important: Two Different Hyku Setups

### Standard Hyku (this guide)
- Repository: `hyku-2` or similar standard Hyku repos
- **No submodules** (no hyrax-webapp folder)
- Uses `sc up -d` with manual Puma start
- Requires `rails db:migrate` and `rails db:seed`

### HykuKnapsack (see wvu_knapsack or RepoCamp)
- Repository: `wvu_knapsack`, `pitt2025`, etc.
- **Has submodules** (hyrax-webapp folder)
- Uses `sc up` (auto-starts Puma)
- Does NOT require manual db:migrate/seed
- See: [RepoCamp Initial Setup](https://github.com/RepoCamp/pitt2025/wiki/Initial-Hyku-Setup)

---

This guide is for **standard Hyku**. For knapsack setup, see the RepoCamp wiki or wvu_knapsack notes.

## Prerequisites

- Docker installed and running
- Stack Car (`sc`) CLI installed

## Environment Configuration

### 1. Understanding APP_NAME

**Important:** Stack Car automatically uses your **folder name** as `APP_NAME`. 

For example:
- Folder: `hyku-2` → Admin URL: `admin-hyku-2.localhost.direct`
- Folder: `wvu_knapsack` → Admin URL: `admin-wvu_knapsack.localhost.direct`

**You do NOT need to set `APP_NAME` in `.env`** when using Stack Car.

### 2. Set up .env file

Your `.env` should have:

```bash
APP_NAME=${APP_NAME:-hyku}  # Stack Car will override this with folder name
HYKU_ADMIN_HOST="admin-${APP_NAME}.localhost.direct"
HYKU_DEFAULT_HOST="%{tenant}-${APP_NAME}.localhost.direct"
HYKU_MULTITENANT=true
HYRAX_FLEXIBLE=false  # Set to true to enable flexible metadata
```

---

## Complete Clean Start (Recommended for Branch Switching)

Use this when switching branches or starting fresh:

### Step 1: Clean Everything

```bash
# Stop all running services
docker-compose down -v

# Stop Stack Car proxy
sc proxy down

# Clean all Docker resources (WARNING: removes all unused containers, networks, images)
docker system prune -a
```

**Confirm:** Type `y` when prompted.

### Step 2: Pull Base Images

```bash
docker-compose pull base
```

---

## Building and Running with Stack Car

### Step 1: Start Stack Car Proxy

```bash
sc proxy up
```

**Verify:** Traefik dashboard should be accessible at:  
🔗 https://traefik.localhost.direct/dashboard/#/

### Step 2: Remove docker-compose.override.yml (if it exists)

**Important:** If you have a `docker-compose.override.yml` file, remove it or rename it:

```bash
mv docker-compose.override.yml docker-compose.override.yml.backup
```

The override file with `command: sleep infinity` prevents Puma from starting automatically.

### Step 3: Build and Start Services

**Using Stack Car (Recommended):**

```bash
# Build the application
sc build

# Start services in background
sc up -d

# Check logs to see Puma starting
sc logs web -f
```

**Wait for:** `Listening on http://0.0.0.0:3000` in the logs.

**Note:** Stack Car automatically sets `APP_NAME` from your folder name (e.g., `hyku-2`)

---

## Accessing the Application

### Admin Interface

Once you see `Listening on http://0.0.0.0:3000` in your terminal, visit:

**Admin URL** (automatically based on your folder name):
- Stack Car uses your folder name as APP_NAME
- Folder `hyku` → 🔗 https://admin-hyku.localhost.direct
- Folder `hyku-2` → 🔗 https://admin-hyku-2.localhost.direct

**Default behavior:**
- Database seed automatically creates the admin account with the correct domain
- You should see the Hyku setup screen where you can create tenants

**Alternative - Create Superadmin Manually:**

In a **second terminal**:

```bash
cd /Users/tam0013/Documents/git/hyku-2
sc exec rake hyku:superadmin:create
```

Enter email and password when prompted.

### Create a Tenant

1. Log into the admin interface
2. Create a new tenant (e.g., "testing")
3. Access tenant at: https://testing-hyku-2.localhost.direct (replace `hyku-2` with your folder name)

---

## Alternative: Running Without Stack Car

If you need to run without Stack Car:

### Environment Setup

```bash
# .env.development
APP_NAME=hykudev
HYKU_ADMIN_HOST="hykudev-admin.localhost"
HYKU_DEFAULT_HOST=%{tenant}.localhost
```

### Commands

```bash
# Clean start
docker-compose down -v
docker system prune -a

# Build and run
docker-compose build --no-cache
docker-compose up -d
```

**Access:** http://hykudev-admin.localhost:3000/users/sign_in

---

## Shutting Down

### Stop Application and Services

```bash
# Stop all containers
docker-compose down

# Optional: Remove volumes too
docker-compose down -v
```

### Stop Stack Car Proxy

```bash
sc proxy down
```

---

## Common Issues & Troubleshooting

### Issue: Services won't start

**Solution:**
1. Check Docker is running: `docker ps`
2. Check Stack Car proxy: Visit https://traefik.localhost.direct/dashboard/#/
3. Review logs: `docker-compose logs web`

### Issue: "Not Found" or Routing Error at admin URL

**Symptom:** Error says account/tenant not found or `Apartment::TenantNotFound`

**Root Cause:** Database was seeded with wrong APP_NAME (e.g., `hyku` when folder is `hyku-2`)

**Solution - Clean restart:**
```bash
docker compose down -v  # -v removes database volumes
sc build
sc up -d
```

Wait for `initialize_app` to complete, then access: `https://admin-<folder-name>.localhost.direct`

**Why this happens:**
- Stack Car sets APP_NAME from folder name
- If database was created before Stack Car started, it has wrong domain
- Must clean database volumes to reseed with correct APP_NAME

### Issue: Can't access localhost.direct URLs

**Solution:**
- Ensure Stack Car proxy is running: `sc proxy up`
- Verify your folder name matches the URL (e.g., `hyku-2` → `admin-hyku-2.localhost.direct`)
- Check `/etc/hosts` or DNS resolution for `*.localhost.direct`

### Issue: Port conflicts

**Solution:**
```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process or use different port
```

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Start proxy | `sc proxy up` |
| Stop proxy | `sc proxy down` |
| Build app | `sc build` |
| Start services | `sc up -d` |
| Enter web container | `sc sh` |
| View logs | `docker-compose logs -f web` |
| Stop services | `docker-compose down` |
| Clean everything | `docker system prune -a` |
| Run migrations | `sc sh` then `bundle exec rails db:migrate` |
| Seed database | `sc sh` then `bundle exec rails db:seed` |

---

## Testing Checklist

- [ ] Docker is running
- [ ] Stack Car proxy is up (Traefik dashboard accessible)
- [ ] Correct branch checked out
- [ ] `docker-compose.override.yml` created
- [ ] Services built with `sc build`
- [ ] Services started with `sc up -d`
- [ ] Dependencies installed (`bundle install` and `yarn install`)
- [ ] Puma running (`bundle exec ./bin/web`)
- [ ] Admin interface accessible
- [ ] Tenant created and accessible

---

## Recommended Workflow for Branch Switching

**⚠️ CRITICAL:** Always use `docker compose down -v` to remove database volumes when switching branches. This prevents APP_NAME/domain mismatches.

1. **Stop everything and clean database:**
   ```bash
   docker compose down -v  # -v removes volumes!
   ```

2. **Switch branch:**
   ```bash
   git checkout <branch-name>
   ```

3. **Rebuild and restart:**
   ```bash
   sc proxy up  # Usually already running
   sc build
   sc up -d
   ```

4. **Wait for initialization:**
   - Check logs: `docker compose logs initialize_app -f`
   - Wait for "all migrations have been run"
   - Access https://admin-{folder-name}.localhost.direct

---

## Notes

- **This guide is for standard Hyku** - for knapsack-based setup, see `wvu_knapsack` notes
- **Stack Car uses your folder name** as `APP_NAME` (e.g., `hyku-2` → URLs use `hyku-2`)
- **Don't mix `sc` and `docker-compose` commands** - stick with Stack Car commands when using it
- Always run `rails db:migrate` and `rails db:seed` after first build
- Always wait for Puma to fully start before accessing the application
- When testing different commits, document which SHA you're testing
- Keep this guide updated with any new discoveries or issues

---

## Branch Comparison: Stack Car Issues

### Comparing: feature/hide-metadata-profiles-search-only vs feature/hide-metadata-profiles-search-only-2

**Context:**
- ✅ **Original branch** (`feature/hide-metadata-profiles-search-only`) - **Was working with Stack Car**
- ❌ **-2 branch** (`feature/hide-metadata-profiles-search-only-2`) - **Having issues** - created by extracting only required files from original

**Key Differences Causing Issues in -2 Branch:**

#### 1. Hyrax Version Downgrade
- **Original (working):** `hyrax` branch `hyku_7_main` (Rails 7.2 compatible)
- **-2 branch (issues):** `hyrax` branch `5.0-flexible` (older version)
- **⚠️ Impact:** Downgrade may cause inconsistencies with Rails/gem expectations

#### 2. Good Job Downgrade
- **Original (working):** `good_job ~> 4.10` (Rails 7.2 compatible)
- **-2 branch (issues):** `good_job ~> 2.99` (older version)
- **⚠️ Impact:** May not work properly with newer Rails or ActiveJob setup

#### 3. Dockerfile Regression
- **Original (working):** Uses `bin/rails secret` 
- **-2 branch (issues):** Uses `bin/rake secret` (older command)
- **⚠️ Impact:** Inconsistent with Rails 7.2 conventions, may cause build issues

#### 4. Docker Compose Changes
- **-2 branch adds:** `bundle &&` step before `db-migrate-seed.sh` 
- **⚠️ Impact:** Suggests dependencies weren't installing correctly, band-aid fix

#### 5. Gem Version Mismatches
- **hyrax-doi:** Downgraded from rails_hyrax_upgrade branch to stable tag v0.3.0
- **iiif_print:** Changed from git branch `fix_metadata_include` to stable `~> 3.0.5`
- **riiif:** Changed from stable `~> 2.1` to git commit `9a375` (inconsistent direction)
- **Apartment gem:** Switched from `ros-apartment` (Rails 7.2 fork) back to older `apartment`
- **⚠️ Impact:** These downgrades may not be compatible with newer Rails 7.2 code

#### 6. Knapsack Revision Mismatch
- Different commits on `required_for_knapsack_instances` branch
- **⚠️ Impact:** May be missing bug fixes or required changes

**Root Cause Analysis:**

The **-2 branch appears to have dependency conflicts** from mixing:
- Older gem versions (Hyrax 5.0, Good Job 2.99)
- Potentially newer application code expecting Rails 7.2 features
- Incomplete file extraction missing necessary compatibility changes

**Recommended Debugging Steps for -2 Branch:**

1. **Check what files were NOT extracted:**
   ```bash
   git diff --name-status feature/hide-metadata-profiles-search-only-2 feature/hide-metadata-profiles-search-only
   ```

2. **Compare initializers and config files:**
   - Look for missing configuration in `config/initializers/`
   - Check `config/application.rb` and environment files

3. **Verify all decorators were included:**
   - The -2 branch moved `environment_decorator.rb` - ensure path is correct
   - Check all controller/model decorators are present

4. **Look for missing migration or seed changes:**
   - Database setup might be incomplete

5. **Review removed JavaScript:**
   - Removed `autocomplete/linked_data.es6` - might be needed

**Understanding the Branch Context:**

The **-2 branch** is a clean extraction for PR #2861 targeting `6.2-stable`. It includes only:
- `app/indexers/app_indexer.rb` - Adds `schema_version_tesim` indexing
- `app/views/hyrax/dashboard/sidebar/_metadata.html.erb` - Sidebar menu item for metadata profiles
- `config/locales/en.yml` - Translation keys
- `spec/features/sidebar_metadata_profiles_spec.rb` - Feature spec

**Current Status:** 12 test failures on PR #2861

---

## Stack Car Testing Strategy for -2 Branch

**Goal:** Test the metadata profiles feature locally with Stack Car before merging to 6.2-stable

### Prerequisites for Testing

The feature requires these conditions to show the Metadata Profiles link:
1. ✅ `Hyrax.config.flexible?` must be true (set `HYRAX_FLEXIBLE=true` in `.env`)
2. ✅ User must have permission: `can?(:manage, Hyrax::FlexibleSchema)`
3. ✅ `Site.account&.search_only?` must be **false**
4. ✅ `metadata_profiles_path` must be defined (route must exist)

### Step-by-Step Test Plan

1. **Checkout the -2 branch:**
   ```bash
   cd /Users/tam0013/Documents/git/hyku-2
   git checkout feature/hide-metadata-profiles-search-only-2
   ```

2. **Update environment for flexible metadata:**
   ```bash
   # Edit .env and ensure:
   HYRAX_FLEXIBLE=true
   ```

3. **Clean build with Stack Car:**
   ```bash
   docker-compose down -v
   sc proxy down
   docker system prune -a
   
   # Start fresh
   sc proxy up
   sc build
   sc up -d
   ```

4. **Enter container and setup:**
   ```bash
   sc sh
   bundle install
   yarn install
   bundle exec ./bin/web
   ```

5. **Test the feature:**
   - Login as admin: https://APP_NAME-admin.localhost.direct
   - Create a tenant (make sure it's NOT search-only)
   - Login to tenant dashboard
   - Check if "Metadata Profiles" appears in sidebar under Settings

6. **Run the specific spec:**
   ```bash
   # Inside the container
   bundle exec rspec spec/features/sidebar_metadata_profiles_spec.rb
   ```

### Common Stack Car Issues for -2 Branch

#### Issue: Routes for metadata_profiles_path missing
**Symptom:** Link doesn't appear even with `HYRAX_FLEXIBLE=true`

**Solution:**
```bash
# Check if route exists (inside container)
bundle exec rails routes | grep metadata_profile
```
If missing, the flexible metadata engine might not be loaded.

#### Issue: schema_version method missing
**Symptom:** Indexing errors or test failures

**Cause:** The `app_indexer.rb` adds `schema_version_tesim` but object might not respond to `schema_version`

**Check:**
```bash
# Verify model has schema_version attribute
bundle exec rails console
> Work.new.respond_to?(:schema_version)
```

#### Issue: Site.account.search_only not defined
**Symptom:** NoMethodError on `search_only?`

**Solution:** Ensure the Account model has the `search_only` attribute/method.

### Test Failure Debugging

If you're seeing the **12 test failures** from PR #2861:

1. **Check test output locally:**
   ```bash
   sc sh
   bundle exec rspec --format documentation
   ```

2. **Most likely failures:**
   - Missing routes for metadata profiles
   - Missing `schema_version` attribute on work models  
   - Missing `search_only` attribute on Account model
   - Flexible metadata configuration not loaded

3. **Quick diagnostic:**
   ```bash
   # Inside container
   bundle exec rails runner "puts Hyrax.config.flexible?"
   bundle exec rails runner "puts Site.instance.account.respond_to?(:search_only?)"
   ```

### If Tests Still Fail

The -2 branch might be missing dependencies that exist in the original branch. Compare:

```bash
# See what's different in config/initializers
git diff origin/feature/hide-metadata-profiles-search-only feature/hide-metadata-profiles-search-only-2 -- config/

# Check for missing migrations
git diff origin/feature/hide-metadata-profiles-search-only feature/hide-metadata-profiles-search-only-2 -- db/migrate/
```

**Alternative:** Test on the working original branch first, then extract *only* the working files.

---

**Last Updated:** Based on notes through 08/06/2025 + PR #2861 analysis 01/15/2026
