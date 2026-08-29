import QtQuick
import qs.Commons

// Scale the bar's icon glyphs on their own, without dragging every other piece
// of shell text along. `[font] base-size` is the only sizing knob Omarchy
// exposes, and it is the rem root for the whole shell: pushing it up to make
// the icons legible also grows the clock, the panels, the menu and the
// notifications. The bar's own icon tokens (`icon-font`, `icon-canvas`,
// `icon-slot`) would be the right lever, but Style.applyShellValues only reads
// `size-horizontal`, `size-vertical` and `scale-with-font` out of a theme's
// `[bar]` section, so those three keys are unreachable from shell.toml — set
// them there and nothing happens.
//
// Style.barOverrides itself is a plain writable property, though, and
// Style.barToken() reads it on every access, so writing the tokens in from here
// works and keeps following `base-size` (barToken multiplies by fontScale).
// Everything stays expressed in stock 12px-base units, exactly like the
// defaults, so the two knobs compose instead of fighting.
Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  // Stock values from Style.bar, the baseline every scale is applied to.
  readonly property int defaultIconFont: 13
  readonly property int defaultIconCanvas: 16
  readonly property int defaultIconSlot: 27

  readonly property var barConfig: shell && shell.shellConfig && shell.shellConfig.bar ? shell.shellConfig.bar : ({})

  // Absent, unparseable or 1 all mean "leave the stock sizes alone", in which
  // case the tokens are handed back rather than pinned to today's defaults.
  readonly property real iconScale: {
    var n = Number(barConfig.iconScale)
    if (!isFinite(n) || n <= 0) return 1
    return n
  }

  // The slot is the button's cross-axis extent, i.e. the glyph plus its
  // padding. Growing it proportionally would multiply the padding too and blow
  // the bar out sideways, so it takes the canvas's absolute growth instead and
  // the gaps between icons stay put.
  function tokens() {
    if (iconScale === 1) return ({})
    var canvas = Math.round(defaultIconCanvas * iconScale)
    return {
      "icon-font": Math.round(defaultIconFont * iconScale),
      "icon-canvas": canvas,
      "icon-slot": defaultIconSlot + (canvas - defaultIconCanvas)
    }
  }

  // Re-applied rather than applied once: Style.applyShellValues rebuilds
  // barOverrides from scratch on every theme switch and on every shell.toml
  // change, dropping anything that did not come out of the TOML.
  function apply() {
    var current = Style.barOverrides || ({})
    var wanted = tokens()
    var keys = ["icon-font", "icon-canvas", "icon-slot"]
    var next = ({})
    var changed = false

    for (var k in current) next[k] = current[k]
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]
      var value = wanted[key]
      if (value === undefined) {
        if (key in next) { delete next[key]; changed = true }
      } else if (Number(next[key]) !== value) {
        next[key] = value
        changed = true
      }
    }

    // Guarded: the write below re-enters through onBarOverridesChanged.
    if (changed) Style.barOverrides = next
  }

  onIconScaleChanged: apply()

  Connections {
    target: Style
    function onBarOverridesChanged() { root.apply() }
  }

  Component.onCompleted: apply()
}
