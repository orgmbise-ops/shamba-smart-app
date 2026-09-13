# Shamba Smart — Flutter (Hybrid Offline-First IoT App)

Production-ready Flutter codebase for **Shamba Smart** (Farmers Hope), an
agricultural IoT companion for the Farmer-Hub ESP32 edge node.

## Architecture at a glance

| Layer | Mobile (Android/iOS) | Web |
|---|---|---|
| Local store | Isar (`DatabaseService`) | none — reads/writes go straight to Supabase |
| Hardware | BLE (`flutter_blue_plus`) → MQTT fallback | MQTT / Supabase Realtime only (no BLE on web) |
| Sync | `SyncService` pushes unsynced Isar rows on reconnect, pulls news/weather caches | Always "online-first"; sync push step is a no-op |
| AI | `GeminiService`, BYOK key in `flutter_secure_storage` | same |

The offline mutation queue pattern: every write (a manual soil log, a pump
toggle) is saved to Isar first with `isSynced = false`. `SyncService`
listens to `connectivity_plus`; the moment the device comes back online it
bulk-upserts every unsynced row into Supabase and flips the flag.

## Project layout

```
lib/
  main.dart                     — bootstraps Isar, Supabase, then runs the app
  theme/app_theme.dart          — Smart Farm dark design system
  models/                       — Isar collections: SoilLog, FarmNews,
                                   WeatherForecast, ActuatorState
  services/
    database_service.dart       — single Isar instance + CRUD/streams
    sync_service.dart           — offline-first push/pull engine
    connection_manager.dart     — BLE (FFE0) + MQTT fallback, pump control
    gemini_service.dart         — BYOK AI agronomist + image diagnosis
  providers/app_providers.dart  — Riverpod wiring for all of the above
  screens/
    home_screen.dart            — weather, quick actions, hardware banner, news
    dashboard_screen.dart       — Monitor: live sensor gauges + link badge
    ai_chat_screen.dart         — AI Advisor chat + photo diagnosis
    market_screen.dart, category_screen.dart, biography_screen.dart
    root_shell.dart             — 6-tab bottom navigation
```

## Setup — zero Flutter experience needed

You do **not** need to install Flutter, Android Studio, or anything else
on your own computer. Everything happens on GitHub's servers via the
included workflow at `.github/workflows/build_apk.yml`. All you do is
upload files and click a couple of buttons in your browser.

### Step 1 — Create a Supabase project (if you don't have one yet)
1. Go to https://supabase.com, sign up, and create a new project.
2. Once it's created, go to **Project Settings → API**. Copy the
   **Project URL** and the **anon public** key — you'll need both shortly.
3. Open the SQL Editor in your Supabase project and run, in order:
   - `shamba_smart_supabase_v3_agentic.sql` (the file you already had)
   - `supabase_app_cache_tables.sql` (included in this zip)

### Step 2 — Put this project on GitHub
1. Go to https://github.com, sign in (or create a free account).
2. Click the **+** in the top right → **New repository**. Name it
   `shamba-smart-app`, keep it **Private** or **Public** (either works),
   and click **Create repository**.
3. On the new repo's page, click **uploading an existing file** (or drag
   files in). Unzip `shamba_smart_flutter_app.zip` on your computer first,
   then drag the **contents** of the `shamba_smart_app` folder (not the
   folder itself) into the GitHub upload box — including the hidden
   `.github` folder. If GitHub's web uploader hides dotfolders, use
   GitHub Desktop (https://desktop.github.com) instead: File → Add Local
   Repository → pick the unzipped folder → Publish repository. This
   preserves `.github/` reliably.
4. Commit the upload.

### Step 3 — Add your Supabase keys as secrets
1. In your new repo, go to **Settings** (top tab) → **Secrets and
   variables** (left sidebar) → **Actions**.
2. Click **New repository secret**. Name it `SUPABASE_URL`, paste your
   Project URL from Step 1, save.
3. Click **New repository secret** again. Name it `SUPABASE_ANON_KEY`,
   paste your anon key, save.

### Step 4 — Build the app
1. Go to the **Actions** tab at the top of your repo.
2. You should see a workflow called **"Build Android APK"** in the left
   sidebar. Click it.
3. Click the **Run workflow** button (top right) → **Run workflow** again
   to confirm.
4. Wait 5-10 minutes. A yellow dot means it's running; a green check
   means it succeeded (a red X means something failed — click into the
   run and copy me the error text if that happens).

### Step 5 — Download and install
1. Click into the finished (green) run.
2. Scroll down to the **Artifacts** section at the bottom of the page.
3. Click **shamba-smart-release-apk** to download it — it's a zip
   containing `app-release.apk`.
4. Unzip it on your computer, then transfer `app-release.apk` to your
   Android phone any way you like: email it to yourself, upload to
   Google Drive and download on the phone, or plug the phone in via USB
   and copy it over.
5. On your phone, open the file. Android will likely block it the first
   time and show **"Install blocked"** — tap **Settings** in that prompt,
   enable **Allow from this source** for the app you used to open the
   file (Files, Chrome, Drive, etc.), then go back and tap the APK again
   → **Install**.
6. Open **Shamba Smart** from your app drawer. That's it — you now have
   it installed for testing.

### Trying it without a real ESP32 yet
The app will run and let you browse every screen even with no hardware
connected — the Monitor screen will just show `--` for sensor values
until either a BLE ESP32 broadcasting service UUID `FFE0` is nearby, or
telemetry starts arriving over MQTT/Supabase. The AI Advisor and
Marketplace tabs work independently of hardware.

## Connecting to the ESP32 — mobile AND web

Both the app and a future web build reach the same physical ESP32, just
over different transports, and everything routes through
`ConnectionManager` so the rest of the app never has to care which one
is active:

| Platform | Primary path | Fallback / only path |
|---|---|---|
| Android/iOS app | **BLE** — tap the Bluetooth icon on the Monitor screen to scan (service UUID `FFE0`) | **MQTT** over TLS, connected automatically in the background whenever you're online, so the pump/telemetry still work if the phone is out of Bluetooth range |
| Web build | *(not available — browsers can't do the kind of BLE scanning this needs)* | **MQTT over secure WebSockets** — the only path on web, connected automatically on load |

This is also why the earlier version of this code had a real bug worth
knowing about: the BLE and MQTT libraries I originally used both depend
on `dart:io`, which **doesn't exist in a browser build at all** — a
`flutter build web` would have failed to compile. I've since split both
into platform-conditional files (`ble_bridge.dart`, `mqtt_factory.dart`)
that pick the right implementation per platform *at compile time*, so
the ESP32-facing code compiles cleanly on both targets, and the web
build automatically gets an MQTT-over-WebSocket connection instead of a
BLE one — it isn't just silently disabled.

### ESP32 firmware contract

- **BLE**: service UUID `FFE0`, telemetry characteristic `FFE1` (notify,
  JSON payload `{"moisture":.., "ph":.., "ec":.., "temp":.., "humidity":..}`),
  pump command characteristic `FFE2` (write single byte `0x01`/`0x00`).
- **MQTT**: telemetry on `shamba/<deviceId>/telemetry` (same JSON), pump
  commands published by the app to `shamba/<deviceId>/pump/set`
  (`{"enabled": true|false}`). The ESP32 needs to publish to/subscribe
  from these exact topics.

### Setting up the MQTT broker (needed for web, optional for mobile)

1. Create a free broker — HiveMQ Cloud (https://www.hivemq.com/mqtt-cloud-broker/)
   is a good option with a generous free tier and built-in WebSocket support.
2. Note your cluster URL, and create a username/password for device + app access.
3. Configure your ESP32 firmware to publish/subscribe on the topics above,
   connecting to the broker on port 8883 (TLS).
4. Add these as GitHub Actions secrets (Settings → Secrets and variables → Actions),
   same place as your Supabase ones:
   - `MQTT_BROKER` — e.g. `xxxxxxxx.s1.eu.hivemq.cloud`
   - `MQTT_USERNAME`
   - `MQTT_PASSWORD`

   If you skip this, the app still works fully offline and the mobile BLE
   path still works — you just won't get the cloud/web fallback until you
   add a broker later.

## Notes / next steps

- `pubspec.yaml` pins stable, widely-used package versions — bump as
  needed, but re-run `build_runner` after any Isar version change.
- Row Level Security is enabled on every Supabase table touched by this
  app; all cloud writes are scoped to `auth.uid()`.
- The Market/Category/Biography screens are intentionally simple stubs —
  wire them to `soil_logs`/marketplace tables as those features mature.
- The `MQTT_WS_PORT` default (8884) assumes a broker exposing MQTT over
  WebSockets on that port, standard for HiveMQ Cloud. If yours differs,
  override it with `--dart-define=MQTT_WS_PORT=xxxx`.
