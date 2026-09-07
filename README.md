# DSML Cleaning Job

A repeatable cleaning job for vorpcore: talk to a job NPC to pick up work, clean every
configured spot, then report back to any job NPC to get paid.

## Features
- One job per town (ships with Blackwater, Saint Denis, Valentine, Rhodes) — each town has its
  own NPC (a real spawned ped, `npc.model`/`coords`/`heading`/optional `scenario` in
  `Config.Towns`, same local/non-networked spawn pattern `vorp_hunting`'s own NPCs use) plus a
  map blip, and its own list of cleaning spots; a job only requires that town's spots
- Add as many towns, or as many spots within a town, as you want
- **Per-town animation/props override**: Valentine and Rhodes clean up manure at their stables
  (`p_horsepoop02x`/`03x` + the `gravedigging` shovel animation) instead of general street
  litter with a broom - any town can set its own `garbageProps`/`cleaningAnimation` the same
  way (`Config.Towns`), overriding the resource-wide `Config.GarbageProps`/`CleaningAnimation`
  defaults. This absorbs what used to be a separate resource, `dsml_scleaner` — safe to stop/
  remove that one once this is confirmed working in-game
- Each job only asks for a random subset of a FLAT (ungrouped) town's spots (configurable), so
  it's not the same fixed route every time
- **Named places** (both Blackwater and Saint Denis use this): a town's `spots` can instead be
  grouped into sub-places (e.g. `station`/`supremecourt`) — one place is picked at random per
  job, and EVERY spot in it is required (not a further random subset — picking the place already
  is the "not the whole town" narrowing), so a job sends you to one coherent location instead of
  making you crisscross town. Opt-in per town — see `Config.Towns` below
- Any job NPC can turn in a finished job, regardless of which town it came from
- **Garbage props**: every remaining spot in the active job spawns a garbage/debris prop
  (`Config.GarbageProps`, random model per spot) so the spots actually look like they need
  cleaning — it despawns the moment that spot is cleaned
- Persistent HUD showing live progress (`X / N spots cleaned`) while a job is active
- Per-character cooldown after finishing a job — a fresh random wait (5-10 min by default) is
  rolled each time, not the same fixed delay every time (`Config.JobCooldown`)
- **No jobs at night**: server-authoritative, off `weathersync`'s synced clock (`Config.NightRestriction`) -
  the popup shows "too dark to clean" and disables Get a Job proactively; a modified client
  trying anyway still gets rejected server side
- Cleaning animation via `vorp_animations` (broom prop included) + `dsml_progressbar` for the
  per-spot cleaning action
- Map blips + a GPS route line to the nearest remaining spot, plus a floating ground marker
  once you're close — so spots are findable from across town, not just up close
- NUI popup themed to match `dsml_crafting` / `dsml_progressbar`

## How it works
1. Walk up to a town's job NPC, press **G**, click **Get a Job** — assigns a random subset of
   that town's spots (`Config.SpotDrop`) for a flat town, or ALL of one randomly-picked place's
   spots for a town with named places (no subset - see `Config.Towns`).
2. Each remaining spot shows as a blip on the map, with a GPS route line to the nearest one;
   once you're close, a floating ground marker takes over and a garbage prop marks the exact
   spot. The HUD tracks overall progress. Press **G** to clean a spot — plays a sweeping
   animation (via `vorp_animations`) and a `dsml_progressbar` bar for `Config.CleanTime` ms,
   then the prop despawns.
3. Once every spot in that town is done, go to **any** job NPC and click **Finish the Job**
   to get paid.
4. That character can't pick up another job for a random `Config.JobCooldown.min`-`max` wait
   after finishing. Jobs also can't be picked up at all during `Config.NightRestriction`'s
   hours, regardless of cooldown.

## Configuration
Everything lives in `config.lua`:
- `Config.Towns` — each entry is a self-contained town: `id`, `name`, one `npc` (model,
  coords, heading, optional idle scenario, optional map blip), and its own `spots` list.
  Add more towns, or more spots to an existing town, and everything else just works. `spots`
  can be either a flat array of `{label, coords}` entries (Valentine/Rhodes below), or a table
  of named PLACES each holding its own flat array (Blackwater/Saint Denis below) — see the big
  comment above `Config.Towns` in `config.lua` for the exact shape. When it's the latter, one
  place is picked at random per job (`Config.PickTownArea`/`Config.ResolveTownSpots`, shared
  between server/client so they always resolve a given job's spot indexes the same way) and
  EVERY spot in it is required — `Config.SpotDrop` does not apply to a place, only to a flat
  town's spots. The job HUD shows which place got picked (e.g. "Saint Denis — Station") via
  `Config.AreaLabel`. A town can also set its own `garbageProps`/`cleaningAnimation` to override
  `Config.GarbageProps`/`Config.CleaningAnimation` just for it (Valentine/Rhodes do this).
- `Config.Reward` — currency type (money/gold) and amount paid on completion
- `Config.JobCooldown` — `{min, max}` in ms; a fresh random cooldown in that range is rolled per
  character every time a job is finished
- `Config.NightRestriction` — `{enable, startHour, endHour}` (24h, wraps past midnight); jobs
  can't be picked up while the current hour (from `exports.weathersync:getTime()`, the same
  synced clock this install's day/night cycle already follows) falls in that range. Set
  `enable = false` to allow jobs at any hour. Fails open (never blocks) if `weathersync` isn't
  running
- `Config.CleanTime` — how long (ms) cleaning a single spot takes
- `Config.CleaningAnimation` — DEFAULT key of the animation played while cleaning, looked up via
  `vorp_animations`' shared `initiate()` export (built-in `sweeping` broom animation — see
  `resources/[VORP]/vorp_animations/config.lua` for other options, or register your own with
  `Animations.registerAnimation(...)`); override per-town with a `cleaningAnimation` field
- `Config.GarbageProps` — DEFAULT list of garbage/debris prop models, one picked at random per
  spot; spawned while a spot is dirty and despawned once it's cleaned. Set to `{}` to disable
  prop spawning entirely; override per-town with a `garbageProps` field
- `Config.SpotMarker` — the floating ground marker shown on remaining spots (type, render
  distance, scale, color); set to `nil` to disable it
- `Config.SpotBlip` — map blip + GPS route line to the nearest remaining spot (sprite, color,
  scale, whether to draw the route line); set `enable = false` to disable it
- `Config.SpotDrop` — how many of a FLAT town's spots get randomly left out of each job
  (`min`/`max`, always leaves at least 1); set `max = 0` to always require every configured
  spot. No effect on a town using named places — a place always requires every spot in it

The example Blackwater/Saint Denis NPC and spot coordinates in `config.lua` are anchored
near other resources' verified NPC spots in this install (vorp_banking's bank tellers,
vorp_stores' general store/butcher); Valentine/Rhodes' are anchored to `vorp_stables`' own
verified EnterStable/StableNPC/SpawnHorse coords. Exact placements are **not** otherwise
verified in-game — check for wall-clipping/bad ground before going live.

## Security

Before this pass, `CleanSpot` had **no server-side re-validation at all** — the
client's own local `dsml_progressbar` ran the `Config.CleanTime` wait, then
just fired the event; the server counted whatever spot index it was told,
from wherever the player actually was, as fast as it arrived. A modified
client could report every spot in a job cleaned in a single burst, from
anywhere on the map, with zero real wait. Two gaps closed:

- **No distance check** — `CleanSpot` now re-verifies the reporting player
  is actually near that spot's coords (`Config.Distances.spot` +
  `Config.Security.SpotDistanceTolerance`) via
  `exports.dsml_security:ValidateDistance`.
- **No timing enforcement** — since this resource's progress bar is
  client-driven (not a server-owned wait the way `dsml_mining`/
  `dsml_lumberjack` use), the closest equivalent without a full
  re-architecture is a minimum-elapsed check: each job tracks
  `phaseStartedAt`, reset every time a spot is accepted, and `CleanSpot`
  rejects a request that arrives sooner than `Config.CleanTime *
  Config.Security.TimingTolerancePct` since that mark. Walking to the next
  spot only ever adds real elapsed time, so this never false-positives
  normal play — it only catches a spot reported clean faster than physically
  possible.

Because the server can now reject a spot it used to always accept, the client
no longer marks a spot cleaned (or despawns its garbage prop) optimistically
— it waits for the new `dsml_cleaningjob:client:cleanResult` reply and only
commits local state on success, resyncing on a rejection instead of drifting
out of sync with the server's own count.

Also fixed: **`FinishJob`'s own double-payout race** — `TriggerEvent`ing
`dsml_quests:activityCompleted` runs that handler synchronously in the same
coroutine, and it can yield internally (its own reward-granting
`vorp_inventory` calls); a second, concurrent `FinishJob` arriving while the
first was suspended there used to still see the untouched job and pay out
again. `activeJobs[source]` is now cleared *before* anything that can yield,
backed by a lock (`exports.dsml_security:AcquireAction`) as defense in depth.

`GetJob`/`CleanSpot`/`FinishJob` are also now rate-limited and strictly
validate their arguments, routed through the shared
[`dsml_security`](../dsml_security) resource (hard dependency). See that
resource's own README for the full API, and `config.lua`'s `Config.Security`
block for this resource's own tuning.

## Dependencies
- vorp_core
- vorp_animations
- dsml_progressbar
- dsml_security (shared rate-limit/validation/suspicious-logging toolkit — see "Security" above)

## UI development
The shipped NUI (`ui/index.html`, `ui/bundle/*`) is a **prebuilt** React app — RedM's CEF
just serves static files, there's no bundler at runtime. Source lives in `ui-src/`:

```
cd ui-src
npm install
npm run build   # compiles into ../ui (index.html + ui/bundle/*.js/.css)
npm run dev     # live-reload preview in a normal browser (uses mock DEV_MODE in App.jsx)
```

Always run `npm run build` after editing anything in `ui-src/` and commit the regenerated
`ui/index.html` + `ui/bundle/*` — those are what the resource actually loads in-game.
