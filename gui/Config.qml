pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Color scheme
  property color ssAccent: "#7aa2f7"
  property color recAccent: "#f7768e"
  property color bgColor: "#13141d"
  property color surfaceColor: "#1a1b26"
  property color textColor: "#c0caf5"
  property color textMuted: "#565f89"
  property color borderColor: "#2a2d3e"
  property color overlayColor: "#000000"
  property real overlayAlpha: 0.5
  property color handleColor: "#ffffff"
  property color dimLabelBg: "#000000"
  property real dimLabelAlpha: 0.75
  property color instructionColor: "#ffffff"
  property real instructionAlpha: 0.65

  // Behavior
  property bool quickCapture: false

  // Paths - centralized configuration
  readonly property string homePath: Quickshell.env("HOME")
  readonly property string configPath: homePath + "/.config/msnap/gui.conf"
  readonly property string mshotPath: homePath + "/.local/bin/mshot"
  readonly property string mcastPath: homePath + "/.local/bin/mcast"
  readonly property string pidFilePath: "/tmp/mcast.pid"

  // UI Constants
  readonly property int panelWidth: 276
  readonly property int panelBottomMargin: 68
  readonly property int buttonHeight: 64
  readonly property int toggleButtonSize: 36
  readonly property int defaultSpacing: 6
  readonly property int defaultBorderRadius: 8

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    onTextChanged: root.loadConfig(text())
    onLoadFailed: reloadTimer.start()
  }

  Timer {
    id: reloadTimer
    interval: 1000
    repeat: false
    onTriggered: configFile.reload()
  }

  function loadConfig(data) {
    if (!data)
      return;

    try {
      const lines = data.split('\n');
      const updates = {};

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#'))
          continue;

        const eqIndex = trimmed.indexOf('=');
        if (eqIndex === -1)
          continue;

        const key = trimmed.substring(0, eqIndex).trim();
        const value = trimmed.substring(eqIndex + 1).trim();

        // Convert snake_case to camelCase
        const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());

        if (camelKey in root) {
          if (value === "true") updates[camelKey] = true;
          else if (value === "false") updates[camelKey] = false;
          else updates[camelKey] = value;
        }
      }

      // Batch update to minimize binding notifications
      for (const [key, value] of Object.entries(updates)) {
        root[key] = value;
      }
    } catch (error) {
      console.error("Config parsing error:", error);
      console.error("Falling back to default configuration");
    }
  }
}
