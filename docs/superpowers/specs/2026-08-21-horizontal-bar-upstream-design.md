# Horizontal Bar + Upstream Merge Strategy — Design

Date: 2026-08-21
Repo: ~/.config/quickshell/caelestia (fork of caelestia-dots/shell)

## Goals

1. Replace the vertical (left-edge) bar with a horizontal top-edge bar. Full replacement, no config toggle.
2. Establish a fork-maintenance strategy + opencode skill so future upstream merges stay cheap.

## Current state

- Branch `test` = `main` + 1 local commit (`3136a15b "temp 1"`: gif swaps, 1 line in `userpaths.hpp`).
- `main` == `upstream/main`. Remote `upstream` already configured.
- Bar is embedded in the fullscreen "drawers" window (`modules/drawers/ContentWindow.qml`), anchored left; all drawer geometry offsets by `bar.implicitWidth` on the X axis.

## A. Git strategy

```
upstream/main --ff-only--> main   (pristine mirror, never commit directly)
                  |
                  +--rebase--> test  (all custom commits, linear history)
                                   |
                                   +--> origin/test (push --force-with-lease)
```

- Sync via rebase, never merge → conflicts resolved per-commit instead of big-bang.
- Refactor split into area-scoped commits so rebase conflicts stay localized.

## B. Horizontal bar refactor (top edge)

Ordered commits, each keeps the shell runnable:

1. **Bar.qml** — ColumnLayout→RowLayout; hit-test axis swap in `checkPopout`/`handleWheel` (`childAt(x, height/2)`); `currentCenter` on X axis; padding margins left/right.
2. **BarWrapper.qml** — animate `implicitHeight`; anchors left/right; `exclusiveZone` from height; Loader anchors bottom.
3. **Components** — swap vertical-strip sizing (`Tokens.sizes.bar.innerWidth = 40`) to horizontal; Workspaces redesigned from vertical stack to horizontal row (incl. ActiveIndicator, OccupiedBg, Workspace, SpecialWorkspaces); Tray, StatusIcons, Clock, ActiveWindow flow horizontally.
4. **Drawers geometry** — ContentWindow.qml (`BlobInvertedRect.borderLeft`→`borderTop`, PanelBg y-offsets), Regions.qml (x-based math → y-based), Panels.qml (`anchors.leftMargin`→`topMargin`).
5. **Interactions.qml** — hover/drag logic for top bar (`y < clampedHeight` triggers, drag-down shows bar, panel hit-test helpers remapped).
6. **Popouts** — ClipWrapper slides in from top, positions along X using `currentCenter`.
7. **Stragglers** — Background.qml:67 wallpaper margin, launcher/WallpaperList.qml popout check.
8. **C++ tokens** — only if needed (e.g. new size semantics).

~15 files touched total. Known impact map (from code trace):

| Area | Files |
|---|---|
| Bar core | modules/bar/Bar.qml, BarWrapper.qml |
| Components | components/{Workspaces→workspaces/*, Tray, StatusIcons, Clock, ActiveWindow, OsIcon, Power} |
| Drawers | drawers/{ContentWindow, Regions, Panels, Interactions}.qml |
| Popouts | popouts/ClipWrapper.qml (+ Wrapper currentCenter consumers) |
| Stragglers | background/Background.qml, launcher/WallpaperList.qml |

## C. Skill: caelestia-upstream

Path: `~/.config/opencode/skills/caelestia-upstream-merge/SKILL.md`

Triggers: "merge upstream", "sync upstream", "update from caelestia".

Contents:
- Exact git procedure: fetch upstream → checkout main, merge --ff-only upstream/main → checkout test, rebase main → resolve using conflict-prone file map → verify → push origin main (ff) + test (--force-with-lease).
- Conflict-prone file list (the ~15 files above) with per-file notes on what the custom commits change.
- Verification checklist: qmllint conventions script, quickshell reload smoke test.
- Rollback notes (rebase --abort, reflog).

## Non-goals

- No config toggle between vertical/horizontal.
- No upstream PR; this stays a personal fork.
