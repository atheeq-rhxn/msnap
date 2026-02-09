import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Screenshot tool popup for quickshell
// Integrates with mango-utils/mshot and mcast for capture functionality
PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: true
  color: "transparent"

  // Layer shell configuration
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "screencast-tool"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // ===== STATE =====
  property bool isScreenshotMode: true
  property string captureMode: "region"

  // Region selection state
  property bool isRegionSelected: false
  property int selectedX: 0
  property int selectedY: 0
  property int selectedWidth: 0
  property int selectedHeight: 0

  // Reset region selection when mode changes
  onCaptureModeChanged: isRegionSelected = false
  onIsScreenshotModeChanged: {
    isRegionSelected = false
    // Switch away from window mode when entering recording mode
    if (!isScreenshotMode && captureMode === "window") {
      captureMode = "region"
    }
  }

  // ===== RECORDING STATE =====
  property bool isRecordingActive: false

  // FileView to watch recording status via PID file
  FileView {
    id: recordingPidFile
    path: "/tmp/mcast.pid"
    watchChanges: true
    printErrors: false
    
    onLoaded: {
      // PID file exists - recording is active
      isRecordingActive = true
    }
    
    onLoadFailed: {
      // PID file doesn't exist - recording stopped
      if (isRecordingActive) {
        isRecordingActive = false
        // If main panel is hidden, quit the shell entirely after a short delay
        // to allow mcast to send the notification
        if (!root.visible) {
          quitTimer.start()
        }
      }
    }
  }

  // ===== THEME =====
  readonly property color bgColor: "#1a1b26"
  readonly property color surfaceColor: "#24283b"
  readonly property color accentColor: isScreenshotMode ? "#7aa2f7" : "#f7768e"
  readonly property color textColor: "#a9b1d6"
  readonly property color textMuted: "#565f89"
  readonly property color borderColor: "#414868"

  // ===== PATHS =====
  readonly property string homePath: Quickshell.env("HOME")

  // ===== FUNCTIONS =====
  function close() {
    visible = false
    Qt.quit()
  }

  function executeAction() {
    // Common workflow for both screenshot and recording:
    // Region mode requires two steps: select region → execute
    // Window and Screen modes execute directly

    if (captureMode === "region" && !isRegionSelected) {
      // Step 1: Open region selector (for both modes)
      root.visible = false
      regionSelector.open()
      return
    }

    // Step 2: Execute the actual capture/recording
    if (isScreenshotMode) {
      executeScreenshot()
    } else {
      executeRecording()
    }
  }

  function executeScreenshot() {
    var args = [homePath + "/.local/bin/mshot"]

    if (captureMode === "region" && isRegionSelected) {
      // Use -g with pre-selected geometry
      args.push("-g")
      args.push(selectedX + "," + selectedY + " " + selectedWidth + "x" + selectedHeight)
    } else if (captureMode === "window") {
      args.push("-w")
    }
    // screen mode: no additional args needed

    Quickshell.execDetached(args)
    close()
  }

  function executeRecording() {
    // Start recording with the selected mode
    var args = [homePath + "/.local/bin/mcast", "--toggle"]

    if (captureMode === "region" && isRegionSelected) {
      // Use -g with pre-selected geometry
      args.push("-g")
      args.push(selectedX + "," + selectedY + " " + selectedWidth + "x" + selectedHeight)
    } else if (captureMode === "window") {
      args.push("-w")
    }
    // screen mode: no additional args needed

    Quickshell.execDetached(args)
    isRecordingActive = true
    
    // Hide the main panel but keep shell running for the indicator
    root.visible = false
  }

  function stopRecording() {
    Quickshell.execDetached([homePath + "/.local/bin/mcast", "--toggle"])
    isRecordingActive = false
    
    // If main panel is hidden, quit the shell entirely after a short delay
    // to allow mcast to send the notification
    if (!root.visible) {
      quitTimer.start()
    }
  }

  // Timer to delay quitting so mcast can show the notification
  Timer {
    id: quitTimer
    interval: 500
    running: false
    repeat: false
    onTriggered: Qt.quit()
  }

  // ===== REGION SELECTOR =====
  RegionSelector {
    id: regionSelector

    onSelectionComplete: (x, y, w, h) => {
      selectedX = x
      selectedY = y
      selectedWidth = w
      selectedHeight = h
      isRegionSelected = true
      regionSelector.close()
      root.visible = true
    }

    // When user cancels (Esc or right-click in RegionSelector)
    onCancelled: {
      // Restore shell panel and keep tool open
      root.visible = true
    }
  }

  // ===== RECORDING INDICATOR =====
  PanelWindow {
    id: recordingIndicator

    screen: Quickshell.screens[0]

    anchors.top: true
    anchors.right: true

    visible: isRecordingActive
    color: "transparent"

    // Fixed size - positioned with margin
    implicitWidth: 80
    implicitHeight: 100

    // Layer shell configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "recording-indicator"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Indicator width properties
    property int indicatorMinWidth: 6
    property int indicatorExpandedWidth: 56
    property bool isHovered: false

    // Container for the indicator bar with margins
    Item {
      id: indicatorContainer
      anchors.fill: parent
      anchors.topMargin: 40
      anchors.rightMargin: 16
      focus: true

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
          root.stopRecording()
          event.accepted = true
        }
      }

      Component.onCompleted: {
        if (visible) forceActiveFocus()
      }

      onVisibleChanged: {
        if (visible) forceActiveFocus()
      }

      // Mouse area for hover detection - cover the whole container
      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
          recordingIndicator.isHovered = true
        }
        onExited: {
          recordingIndicator.isHovered = false
        }
        onClicked: root.stopRecording()
      }

      // Vertical bar on right side
      Rectangle {
        id: indicatorBar
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: recordingIndicator.isHovered ? recordingIndicator.indicatorExpandedWidth : recordingIndicator.indicatorMinWidth
        height: recordingIndicator.isHovered ? 56 : 40
        radius: recordingIndicator.isHovered ? 8 : 3
        color: "#f7768e"  // Red/pink accent color

        Behavior on width {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on height {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on radius {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Stop button that appears on hover
        Rectangle {
          id: stopButton
          anchors.centerIn: parent
          width: 32
          height: 32
          radius: 6
          color: "#24283b"
          border.width: 2
          border.color: "#f7768e"
          opacity: recordingIndicator.isHovered ? 1.0 : 0.0
          visible: opacity > 0.01

          Behavior on opacity {
            NumberAnimation { duration: 150 }
          }

          // Stop icon - centered square
          Rectangle {
            anchors.centerIn: parent
            width: 14
            height: 14
            color: "#f7768e"
            radius: 2
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.stopRecording()
          }
        }

        // Subtle pulsing effect when not hovered
        SequentialAnimation on opacity {
          running: !recordingIndicator.isHovered && recordingIndicator.visible
          loops: Animation.Infinite
          NumberAnimation { to: 0.7; duration: 1000; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
        }
      }
    }
  }

  // ===== UI =====

  // Full-screen container with keyboard focus
  Item {
    anchors.fill: parent
    focus: true

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Escape) {
        root.close()
        event.accepted = true
      }
    }

    Component.onCompleted: {
      forceActiveFocus()
    }

    // Full-screen click catcher - closes when clicking outside popup
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.close()

      // Main popup container - sizes based on mutil design
      Rectangle {
        id: popupContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: 280
        height: contentLayout.implicitHeight + 24
        color: bgColor
        radius: 12
        border.width: 1
        border.color: borderColor

        // Block clicks from passing through to background
        MouseArea {
          anchors.fill: parent
        }

        // Content
        ColumnLayout {
          id: contentLayout
          anchors.centerIn: parent
          spacing: 12

          // Mode Toggle (Photo/Video) - matching mutil sizing
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 244
            Layout.preferredHeight: 36
            color: surfaceColor
            radius: 8

            RowLayout {
              anchors.fill: parent
              anchors.margins: 4
              spacing: 6

              // Photo button
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: isScreenshotMode ? accentColor : "transparent"
                radius: 6

                Text {
                  anchors.centerIn: parent
                  text: "Screenshot"
                  color: isScreenshotMode ? bgColor : textColor
                  font.pixelSize: 12
                  font.bold: isScreenshotMode
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: isScreenshotMode = true
                }
              }

              // Video button
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: !isScreenshotMode ? accentColor : "transparent"
                radius: 6

                Text {
                  anchors.centerIn: parent
                  text: "Record"
                  color: !isScreenshotMode ? bgColor : textColor
                  font.pixelSize: 12
                  font.bold: !isScreenshotMode
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: isScreenshotMode = false
                }
              }
            }
          }

          // Capture Mode Icons - matching mutil grid layout
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            // Region
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: captureMode === "region"
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                       : surfaceColor
              radius: 8
              border.width: captureMode === "region" ? 2 : 0
              border.color: accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "◰"
                  color: captureMode === "region" ? accentColor : textColor
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Region"
                  color: captureMode === "region" ? accentColor : textMuted
                  font.pixelSize: 11
                  font.bold: captureMode === "region"
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: captureMode = "region"
              }
            }

            // Window
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: !isScreenshotMode
                       ? Qt.rgba(textMuted.r, textMuted.g, textMuted.b, 0.3)
                       : (captureMode === "window"
                           ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                           : surfaceColor)
              radius: 8
              border.width: captureMode === "window" && isScreenshotMode ? 2 : 0
              border.color: accentColor
              opacity: !isScreenshotMode ? 0.5 : 1.0

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "□"
                  color: !isScreenshotMode
                           ? textMuted
                           : (captureMode === "window" ? accentColor : textColor)
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Window"
                  color: !isScreenshotMode
                           ? textMuted
                           : (captureMode === "window" ? accentColor : textMuted)
                  font.pixelSize: 11
                  font.bold: captureMode === "window" && isScreenshotMode
                }
              }

              MouseArea {
                anchors.fill: parent
                enabled: isScreenshotMode
                onClicked: captureMode = "window"
              }
            }

            // Screen
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: captureMode === "screen"
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                       : surfaceColor
              radius: 8
              border.width: captureMode === "screen" ? 2 : 0
              border.color: accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "⛶"
                  color: captureMode === "screen" ? accentColor : textColor
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Screen"
                  color: captureMode === "screen" ? accentColor : textMuted
                  font.pixelSize: 11
                  font.bold: captureMode === "screen"
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: captureMode = "screen"
              }
            }
          }

          // Selected region info (only for region mode when selected)
          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: captureMode === "region" && isRegionSelected
            text: selectedWidth + "x" + selectedHeight
            color: accentColor
            font.pixelSize: 11
            font.bold: true
          }

          // Action Button - matching mutil sizing
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 244
            Layout.preferredHeight: 36
            color: accentColor
            radius: 8

            RowLayout {
              anchors.centerIn: parent
              spacing: 8

              Text {
                text: isScreenshotMode ? "◉" : "⏺"
                color: bgColor
                font.pixelSize: 16
              }

              Text {
                text: {
                  // Show appropriate button text based on state
                  if (captureMode === "region" && !isRegionSelected) {
                    return "Select Region"
                  }
                  if (isScreenshotMode) {
                    return "Capture"
                  }
                  return "Start Recording"
                }
                color: bgColor
                font.pixelSize: 12
                font.bold: true
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: executeAction()
            }
          }
        }
      }
    }
  }
}
