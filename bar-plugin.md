# Floating Pill Bar (som2.bar)

A macOS-style floating status bar for Omarchy 4 "Quattro": a rounded,
translucent glass pill that floats just off the top edge, spans the same
width as your windows, and drops a soft shadow. Double-tap transparency
toggle and all stock bar gestures still work.

Built as a user plugin clone of the stock `omarchy.bar`, so nothing in
`/usr/share/omarchy/` is modified and system updates can't clobber it.

![what it looks like](#) — rounded frosted pill, 4px margins, floats 4px off the top edge

---

## Why a clone instead of editing the stock bar

`/usr/share/omarchy/shell/plugins/bar/Bar.qml` is Omarchy-owned and gets
overwritten on update. The clone lives at
`~/.config/omarchy/plugins/som2.bar/` and survives updates. It also removes
the `required` keyword from three properties (`omarchyPath`,
`barWidgetRegistry`, `barConfig`) that the stock `Bar.qml` declares —
Omarchy's plugin loader can't load bar clones that declare them.

## What the pill styling changes

All changes are inside `component BarPanel: PanelWindow` in `Bar.qml`:

- **Window**: `color: "transparent"` + `surfaceFormat.opaque: false`, and the
  window is made taller/wider than the bar (`barSize + margins + shadow pad`)
  so the floating margins and drop shadow aren't clipped.
- **Pill**: a `Rectangle` (`id: pill`) inside the window with
  `radius: height / 2`, side margins `Style.space(4)`, top margin
  `Style.space(4)`, color `Qt.rgba(0.05, 0.05, 0.09, 0.62)` (0.45 when the
  transparency toggle is on), a 1px hairline border, and a
  `QtQuick.Effects.MultiEffect` drop shadow (blur 1.0, y-offset 6).
- **Content**: the module `Loader` is anchored inside the same margins so
  widgets sit on the pill.
- **Autohide parking**: the stock code parks a hidden bar with
  `margins.top: -root.barSize`. Since the window is now taller than
  `barSize`, the parking margins use the full window height
  (`-(barSize + pillTopMargin + pillShadowPad)`) or the bottom of the pill
  would peek on screen.

The `toggleTransparency()` / `root.transparent` logic is untouched —
double-tap still flips between the two glass opacities.

## Install

```bash
cd omarchy-setup
mkdir -p ~/.config/omarchy/plugins/som2.bar
cp -r bar-plugin/Bar.qml bar-plugin/BarModel.js bar-plugin/manifest.json \
      bar-plugin/widgets bar-plugin/indicators \
      ~/.config/omarchy/plugins/som2.bar/

# enable the clone, disable the stock bar
omarchy plugin enable som2.bar
omarchy plugin disable omarchy.bar
omarchy restart shell
```

Verify:

```bash
omarchy-shell shell listPlugins | grep -A2 bar
# som2.bar  enabled: true  active: true
# omarchy.bar enabled: false active: false
```

## Autohide integration (quattrobar-autohide)

`~/.local/bin/quattrobar-autohide` (copy in `scripts/`) hides the bar when a
window overlaps it and reveals it when the cursor touches the top edge.
Two changes were needed for the clone:

1. The shell nudge after flipping the `bar-off` flag targets the clone's
   IPC handler: `omarchy-shell -q som2.bar syncHidden` (was `omarchy.bar`).
   The clone's `IpcHandler` target in `Bar.qml` is likewise `som2.bar`.
2. `QUATTROBAR_AUTOHIDE_BAR_HEIGHT` default raised 26 → 34 because the pill
   floats 4px lower and the window is taller.

The script is autostarted from `~/.config/hypr/autostart.lua`
(`o.launch_on_start("quattrobar-autohide")`). After editing, restart it:

```bash
pkill -f quattrobar-autohide
setsid nohup ~/.local/bin/quattrobar-autohide >/dev/null 2>&1 &
```

## Tuning

In `Bar.qml`, inside `component BarPanel`:

| Knob | Property | Default |
|---|---|---|
| Side gap | `pillMargin` | `Style.space(4)` |
| Top gap | `pillTopMargin` | `Style.space(4)` |
| Shadow room | `pillShadowPad` | `Style.space(10)` |
| Roundness | pill `radius` | `height / 2` (full pill) |
| Glass (normal) | pill `color` second branch | alpha `0.62` |
| Glass (transparent mode) | pill `color` first branch | alpha `0.45` |
| Shadow | `MultiEffect` in `layer.effect` | blur 1.0, y 6 |

After editing `Bar.qml`, reload the bar and check for errors:

```bash
omarchy restart shell
journalctl --user -b | grep som2.bar
```

## Revert

```bash
omarchy plugin disable som2.bar
omarchy plugin enable omarchy.bar
omarchy restart shell
rm -rf ~/.config/omarchy/plugins/som2.bar
```

And restore the stock autohide nudge target (`omarchy.bar`) in
`~/.local/bin/quattrobar-autohide` if you keep using it.
