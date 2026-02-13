pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

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

  readonly property string configPath: Quickshell.env("HOME") + "/.config/msnap/gui.conf"

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    onTextChanged: {
      root.loadConfig(text())
    }
    onLoadFailed: {
      reloadTimer.start()
    }
  }

  Timer {
    id: reloadTimer
    interval: 1000
    repeat: false
    onTriggered: configFile.reload()
  }

  function loadConfig(data) {
    if (!data) {
      return
    }

    data.split('\n').forEach(line => {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) return

      const parts = trimmed.split('=')
      if (parts.length !== 2) return

      const [key, value] = parts.map(s => s.trim())
      const colorKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())

      if (colorKey in root) root[colorKey] = value
    })
  }
}
