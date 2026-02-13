import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: true
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "msnap"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // Colors from Config
  readonly property color ssAccent: Config.ssAccent
  readonly property color recAccent: Config.recAccent
  readonly property color accentColor: isScreenshotMode ? ssAccent : recAccent
  readonly property color bgColor: Config.bgColor
  readonly property color surfaceColor: Config.surfaceColor
  readonly property color textColor: Config.textColor
  readonly property color textMuted: Config.textMuted
  readonly property color borderColor: Config.borderColor

  function accentBg(mode) {
    const c = mode ? ssAccent : recAccent;
    return Qt.rgba(c.r, c.g, c.b, 0.13);
  }

  property bool isScreenshotMode: true
  property string captureMode: "region"

  // Screenshot specific
  property bool includePointer: false

  // Recording specific
  property bool recordMic: false
  property bool recordAudio: false

  property bool isRegionSelected: false
  property int selectedX: 0
  property int selectedY: 0
  property int selectedWidth: 0
  property int selectedHeight: 0
  property bool isRecordingActive: false

  readonly property string homePath: Quickshell.env("HOME")

  onCaptureModeChanged: isRegionSelected = false

  onIsScreenshotModeChanged: {
    isRegionSelected = false;
    if (!isScreenshotMode && captureMode === "window")
      captureMode = "region";
  }

  FileView {
    id: recordingPidFile
    path: "/tmp/mcast.pid"
    watchChanges: true
    printErrors: false
    onLoaded: isRecordingActive = true
    onLoadFailed: {
      if (isRecordingActive) {
        isRecordingActive = false;
        if (!root.visible)
          quitTimer.start();
      }
    }
  }

  Timer {
    id: quitTimer
    interval: 600
    repeat: false
    onTriggered: Qt.quit()
  }

  function close() {
    visible = false;
    Qt.quit();
  }

  function executeAction() {
    if (captureMode === "region" && !isRegionSelected) {
      regionSelector.open();
      root.visible = false;
      return;
    }
    isScreenshotMode ? executeScreenshot() : executeRecording();
  }

  function executeScreenshot() {
    const args = [homePath + "/.local/bin/mshot"];
    if (captureMode === "region" && isRegionSelected)
      args.push("-g", selectedX + "," + selectedY + " " + selectedWidth + "x" + selectedHeight);
    else if (captureMode === "window")
      args.push("-w");
    if (includePointer)
      args.push("-p");
    Quickshell.execDetached(args);
    close();
  }

  function executeRecording() {
    const args = [homePath + "/.local/bin/mcast", "--toggle"];
    if (captureMode === "region" && isRegionSelected)
      args.push("-g", selectedX + "," + selectedY + " " + selectedWidth + "x" + selectedHeight);
    else if (captureMode === "window")
      args.push("-w");

    // Audio Flags
    if (recordMic)
      args.push("-m");
    if (recordAudio)
      args.push("-a");

    Quickshell.execDetached(args);
    isRecordingActive = true;
    root.visible = false;
  }

  function stopRecording() {
    Quickshell.execDetached([homePath + "/.local/bin/mcast", "--toggle"]);
    isRecordingActive = false;
    if (!root.visible)
      quitTimer.start();
  }

  RegionSelector {
    id: regionSelector

    onSelectionComplete: (x, y, w, h) => {
                           selectedX = x;
                           selectedY = y;
                           selectedWidth = w;
                           selectedHeight = h;
                           isRegionSelected = true;
                           regionSelector.close();
                           root.visible = true;
                         }

    onCancelled: root.visible = true
  }

  PanelWindow {
    id: recordingIndicator

    screen: Quickshell.screens[0]
    anchors.top: true
    anchors.right: true

    visible: isRecordingActive
    color: "transparent"

    implicitWidth: 72
    implicitHeight: 88

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "msnap"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property bool hovered: false

    Item {
      anchors.fill: parent
      anchors.topMargin: 32
      anchors.rightMargin: 12
      focus: true

      Keys.onEscapePressed: root.stopRecording()

      onVisibleChanged: if (visible)
                          forceActiveFocus()
      Component.onCompleted: if (visible)
                               forceActiveFocus()

      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: recordingIndicator.hovered ? 52 : 6
        height: recordingIndicator.hovered ? 52 : 38
        radius: recordingIndicator.hovered ? 9 : 3
        color: root.recAccent

        Behavior on width {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }
        Behavior on radius {
          NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
          }
        }

        Rectangle {
          anchors.centerIn: parent
          width: 14
          height: 14
          radius: 2
          color: root.bgColor
          opacity: recordingIndicator.hovered ? 1.0 : 0.0
          Behavior on opacity {
            NumberAnimation {
              duration: 150
            }
          }
        }

        SequentialAnimation on opacity {
          running: !recordingIndicator.hovered && recordingIndicator.visible
          loops: Animation.Infinite
          NumberAnimation {
            to: 0.5
            duration: 900
            easing.type: Easing.InOutSine
          }
          NumberAnimation {
            to: 1.0
            duration: 900
            easing.type: Easing.InOutSine
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: recordingIndicator.hovered = true
          onExited: recordingIndicator.hovered = false
          onClicked: root.stopRecording()
        }
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true

    function navigateLeft() {
      const modes = ["region", "window", "screen"];
      const availableModes = modes.filter(mode => mode !== "window" || root.isScreenshotMode);
      let currentIndex = availableModes.indexOf(root.captureMode);
      if (currentIndex === -1)
        currentIndex = 0;

      currentIndex = (currentIndex - 1 + availableModes.length) % availableModes.length;
      root.captureMode = availableModes[currentIndex];
    }

    function navigateRight() {
      const modes = ["region", "window", "screen"];
      const availableModes = modes.filter(mode => mode !== "window" || root.isScreenshotMode);
      let currentIndex = availableModes.indexOf(root.captureMode);
      if (currentIndex === -1)
        currentIndex = 0;

      currentIndex = (currentIndex + 1) % availableModes.length;
      root.captureMode = availableModes[currentIndex];
    }

    Keys.onLeftPressed: navigateLeft()
    Keys.onRightPressed: navigateRight()

    Keys.onPressed: event => {
                      if (event.key === Qt.Key_H) {
                        navigateLeft();
                        event.accepted = true;
                      } else if (event.key === Qt.Key_L) {
                        navigateRight();
                        event.accepted = true;
                      } else if (event.key === Qt.Key_J) {
                        root.isScreenshotMode = false;
                        event.accepted = true;
                      } else if (event.key === Qt.Key_K) {
                        root.isScreenshotMode = true;
                        event.accepted = true;
                      } else if (event.key === Qt.Key_P) {
                        if (root.isScreenshotMode) {
                          root.includePointer = !root.includePointer;
                        }
                        event.accepted = true;
                      } else if (event.key === Qt.Key_M) {
                        if (!root.isScreenshotMode) {
                          root.recordMic = !root.recordMic;
                        }
                        event.accepted = true;
                      } else if (event.key === Qt.Key_A) {
                        if (!root.isScreenshotMode) {
                          root.recordAudio = !root.recordAudio;
                        }
                        event.accepted = true;
                      }
                    }

    Keys.onTabPressed: {
      root.isScreenshotMode = !root.isScreenshotMode;
    }

    Keys.onBacktabPressed: {
      root.isScreenshotMode = !root.isScreenshotMode;
    }

    Keys.onReturnPressed: root.executeAction()
    Keys.onEnterPressed: root.executeAction()
    Keys.onSpacePressed: root.executeAction()
    Keys.onEscapePressed: {
      if (isRecordingActive) {
        stopRecording();
      } else {
        root.close();
      }
    }

    onVisibleChanged: if (visible)
                        forceActiveFocus()
    Component.onCompleted: forceActiveFocus()

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.close()

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 68
        width: 276
        height: layout.implicitHeight + 26
        color: root.bgColor
        radius: 12
        border.width: 1
        border.color: root.borderColor

        MouseArea {
          anchors.fill: parent
        }

        ColumnLayout {
          id: layout
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
          }
          spacing: 10

          Rectangle {
            Layout.fillWidth: true
            height: 34
            color: root.surfaceColor
            radius: 8

            RowLayout {
              anchors {
                fill: parent
                margins: 3
              }
              spacing: 3

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: root.isScreenshotMode ? root.ssAccent : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "Screenshot"
                  font.pixelSize: 12
                  font.weight: root.isScreenshotMode ? Font.DemiBold : Font.Normal
                  color: root.isScreenshotMode ? root.bgColor : root.textMuted
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.isScreenshotMode = true
                }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: !root.isScreenshotMode ? root.recAccent : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "Record"
                  font.pixelSize: 12
                  font.weight: !root.isScreenshotMode ? Font.DemiBold : Font.Normal
                  color: !root.isScreenshotMode ? root.bgColor : root.textMuted
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.isScreenshotMode = false
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
              Layout.fillWidth: true
              height: 64
              radius: 8
              color: root.captureMode === "region" ? root.accentBg(root.isScreenshotMode) : root.surfaceColor
              border.width: root.captureMode === "region" ? 1 : 0
              border.color: root.accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                Icon {
                  Layout.alignment: Qt.AlignHCenter
                  name: "crop"
                  color: root.captureMode === "region" ? root.accentColor : root.textMuted
                  size: 20
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Region"
                  font.pixelSize: 11
                  font.weight: root.captureMode === "region" ? Font.DemiBold : Font.Normal
                  color: root.captureMode === "region" ? root.accentColor : root.textMuted
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.captureMode = "region"
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 64
              radius: 8
              enabled: root.isScreenshotMode
              opacity: root.isScreenshotMode ? 1.0 : 0.3
              color: (root.captureMode === "window") ? root.accentBg(root.isScreenshotMode) : root.surfaceColor
              border.width: (root.captureMode === "window") ? 1 : 0
              border.color: root.accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                Icon {
                  Layout.alignment: Qt.AlignHCenter
                  name: "app-window"
                  color: (root.captureMode === "window" && root.isScreenshotMode) ? root.accentColor : root.textMuted
                  size: 20
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Window"
                  font.pixelSize: 11
                  font.weight: (root.captureMode === "window" && root.isScreenshotMode) ? Font.DemiBold : Font.Normal
                  color: (root.captureMode === "window" && root.isScreenshotMode) ? root.accentColor : root.textMuted
                }
              }
              MouseArea {
                anchors.fill: parent
                enabled: root.isScreenshotMode
                cursorShape: root.isScreenshotMode ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.captureMode = "window"
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 64
              radius: 8
              color: root.captureMode === "screen" ? root.accentBg(root.isScreenshotMode) : root.surfaceColor
              border.width: root.captureMode === "screen" ? 1 : 0
              border.color: root.accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                Icon {
                  Layout.alignment: Qt.AlignHCenter
                  name: "device-desktop"
                  color: root.captureMode === "screen" ? root.accentColor : root.textMuted
                  size: 22
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Screen"
                  font.pixelSize: 11
                  font.weight: root.captureMode === "screen" ? Font.DemiBold : Font.Normal
                  color: root.captureMode === "screen" ? root.accentColor : root.textMuted
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.captureMode = "screen"
              }
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.captureMode === "region" && root.isRegionSelected
            text: root.selectedWidth + " × " + root.selectedHeight
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: root.accentColor
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Main Action Button (Record / Capture)
            Rectangle {
              Layout.fillWidth: true
              height: 36
              radius: 8
              color: root.accentColor

              RowLayout {
                anchors.centerIn: parent
                spacing: 7

                Icon {
                  name: "crop"
                  color: root.bgColor
                  size: 18
                  visible: root.captureMode === "region" && !root.isRegionSelected
                }

                Icon {
                  name: "camera"
                  color: root.bgColor
                  size: 18
                  visible: root.isScreenshotMode && !(root.captureMode === "region" && !root.isRegionSelected)
                }

                Icon {
                  name: "player-record"
                  color: root.bgColor
                  size: 16
                  visible: !root.isScreenshotMode && !(root.captureMode === "region" && !root.isRegionSelected)
                }

                Text {
                  text: (root.captureMode === "region" && !root.isRegionSelected) ? "Select Region" : root.isScreenshotMode ? "Capture" : "Start Recording"
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  color: root.bgColor
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.executeAction()
              }
            }

            // Pointer Toggle (Screenshot Mode Only)
            Rectangle {
              width: 36
              height: 36
              radius: 8
              visible: root.isScreenshotMode
              color: root.includePointer ? root.accentBg(true) : root.surfaceColor
              border.width: root.includePointer ? 1 : 0
              border.color: root.ssAccent

              Icon {
                anchors.centerIn: parent
                name: "mouse"
                color: root.includePointer ? root.ssAccent : root.textMuted
                size: 20
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.includePointer = !root.includePointer
              }
            }

            // Mic Toggle (Recording Mode Only)
            Rectangle {
              width: 36
              height: 36
              radius: 8
              visible: !root.isScreenshotMode
              color: root.recordMic ? root.accentBg(false) : root.surfaceColor
              border.width: root.recordMic ? 1 : 0
              border.color: root.recAccent

              Icon {
                anchors.centerIn: parent
                name: "microphone"
                color: root.recordMic ? root.recAccent : root.textMuted
                size: 20
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.recordMic = !root.recordMic
              }
            }

            // Audio/System Sound Toggle (Recording Mode Only)
            Rectangle {
              width: 36
              height: 36
              radius: 8
              visible: !root.isScreenshotMode
              color: root.recordAudio ? root.accentBg(false) : root.surfaceColor
              border.width: root.recordAudio ? 1 : 0
              border.color: root.recAccent

              Icon {
                anchors.centerIn: parent
                name: "volume"
                color: root.recordAudio ? root.recAccent : root.textMuted
                size: 20
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.recordAudio = !root.recordAudio
              }
            }
          }
        }
      }
    }
    onActiveFocusChanged: {
      if (!activeFocus && visible && !regionSelector.visible && !isRecordingActive) {
        root.close();
      }
    }
  }
}
