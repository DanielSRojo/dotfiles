import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Suspend the machine once it has been idle for `idle.suspend` seconds, a key
// Omarchy does not ship. The stock idle service (cloned here as <user>.idle)
// only knows the screensaver and lock steps, and logind's own IdleAction is not
// an option: nothing in the Hyprland session sets the logind idle hint, so the
// session reads as active forever and IdleAction never fires. A separate
// service plugin with its own ext-idle-notify monitor is the seam that works,
// and unlike a patch to the idle clone it survives `omarchy update` untouched.
Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stayAwakeStateDir: home + "/.local/state/omarchy/indicators"
  readonly property var idleConfig: shell && shell.shellConfig && shell.shellConfig.idle ? shell.shellConfig.idle : ({})

  // Absent, unparseable or non-positive all mean "never suspend". There is no
  // built-in default on purpose: an idle suspend nobody asked for is a
  // surprise, and 0 cannot mean "immediately" the way `idle.lock` does.
  readonly property int suspendTimeoutSeconds: {
    var n = Number(idleConfig.suspend)
    if (!isFinite(n) || n <= 0) return 0
    return Math.floor(n)
  }

  readonly property bool enabled: suspendTimeoutSeconds > 0 && stayAwakeStateLoaded && !stayAwake

  property bool stayAwake: false
  property bool stayAwakeStateLoaded: false
  property bool suspendRequested: false
  property string lastEvent: "starting"
  property string lastEventAt: ""

  function logEvent(event, details) {
    var suffix = details === undefined || details === null || details === "" ? "" : ": " + String(details)
    root.lastEventAt = new Date().toISOString()
    root.lastEvent = event + suffix
    console.log("omarchy suspend-on-idle " + root.lastEventAt + " " + root.lastEvent)
  }

  function requestSuspend() {
    // Only on the idle edge. A resume that restores no input (an RTC or Wake-on-
    // LAN wake) leaves the monitor still idle, and re-firing there would put the
    // machine straight back to sleep before anything could use it.
    if (root.suspendRequested) {
      logEvent("suspend-skip", "already requested")
      return
    }
    root.suspendRequested = true
    logEvent("suspend", "idle for " + root.suspendTimeoutSeconds + "s")
    suspendProcess.command = ["systemctl", "suspend"]
    suspendProcess.running = true
  }

  function handleIdleChanged() {
    logEvent("idle-monitor", idleMonitor.isIdle ? "idle" : "active")
    if (idleMonitor.isIdle) {
      if (root.enabled) requestSuspend()
    } else {
      root.suspendRequested = false
    }
  }

  function statusJson() {
    return JSON.stringify({
      enabled: root.enabled,
      timeout: root.suspendTimeoutSeconds,
      stayAwake: root.stayAwake,
      stayAwakeStateLoaded: root.stayAwakeStateLoaded,
      idle: idleMonitor.isIdle,
      suspendRequested: root.suspendRequested,
      suspending: suspendProcess.running,
      lastEvent: root.lastEvent,
      lastEventAt: root.lastEventAt
    })
  }

  function refreshStayAwakeState() {
    if (!stayAwakeStateProbe.running) stayAwakeStateProbe.running = true
  }

  // The same state file the stock idle service and the stay-awake indicator use,
  // so one toggle keeps the whole idle chain — blank, lock, suspend — at bay.
  function applyStayAwake(value) {
    var wasAwake = root.stayAwake
    var loaded = root.stayAwakeStateLoaded
    root.stayAwake = !!value
    root.stayAwakeStateLoaded = true
    if (loaded && wasAwake === root.stayAwake) return

    logEvent("stay-awake", root.stayAwake ? "enabled" : "disabled")
    if (root.stayAwake) root.suspendRequested = false
    else Qt.callLater(root.handleIdleChanged)
  }

  IdleMonitor {
    id: idleMonitor
    enabled: root.enabled
    timeout: root.suspendTimeoutSeconds
    // A media player or an installer holding an idle inhibitor blocks the
    // suspend too, not just the screen blank.
    respectInhibitors: true
    onIsIdleChanged: root.handleIdleChanged()
  }

  Process {
    id: suspendProcess
    onExited: function (exitCode, exitStatus) {
      root.logEvent("suspend-exit", "exitCode=" + exitCode + " status=" + exitStatus)
      // A failed suspend should not wedge the service until the next activity.
      if (exitCode !== 0) root.suspendRequested = false
    }
  }

  Process {
    id: stayAwakeStateProbe
    command: ["bash", "-c", "mkdir -p \"$HOME/.local/state/omarchy/indicators\"; if [[ -f $HOME/.local/state/omarchy/indicators/stay-awake ]]; then echo yes; else echo no; fi"]
    stdout: SplitParser {
      onRead: function (line) { root.applyStayAwake(String(line).trim() === "yes") }
    }
    onExited: function () { stayAwakeStateDirWatcher.reload() }
  }

  FileView {
    id: stayAwakeStateDirWatcher
    path: root.stayAwakeStateDir
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshStayAwakeState()
  }

  Component.onCompleted: {
    logEvent("service-ready", "timeout=" + root.suspendTimeoutSeconds)
    refreshStayAwakeState()
  }

  IpcHandler {
    target: "suspendOnIdle"

    function status(): string {
      return root.statusJson()
    }

    function debug(): string {
      return root.statusJson()
    }
  }
}
