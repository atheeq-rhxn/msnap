import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 1.15
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

  readonly property color ssAccent: "#7aa2f7"
  readonly property color recAccent: "#f7768e"
  readonly property color accentColor: isScreenshotMode ? ssAccent : recAccent
  readonly property color bgColor: "#13141d"
  readonly property color surfaceColor: "#1a1b26"
  readonly property color textColor: "#c0caf5"
  readonly property color textMuted: "#565f89"
  readonly property color borderColor: "#2a2d3e"

  function accentBg(mode) {
    return mode ? Qt.rgba(0.478, 0.635, 0.969, 0.13) : Qt.rgba(0.969, 0.463, 0.557, 0.13);
  }
  property bool isScreenshotMode: true
  property string captureMode: "region"
  property bool includePointer: false
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
      root.visible = false;
      regionSelector.open();
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
      
      onVisibleChanged: if (visible) forceActiveFocus()
      Component.onCompleted: if (visible) forceActiveFocus()

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
      const availableModes = modes.filter(mode => 
        mode !== "window" || root.isScreenshotMode
      );
      
      let currentIndex = availableModes.indexOf(root.captureMode);
      if (currentIndex === -1) currentIndex = 0;
      
      currentIndex = (currentIndex - 1 + availableModes.length) % availableModes.length;
      root.captureMode = availableModes[currentIndex];
    }
    
    function navigateRight() {
      const modes = ["region", "window", "screen"];
      const availableModes = modes.filter(mode => 
        mode !== "window" || root.isScreenshotMode
      );
      
      let currentIndex = availableModes.indexOf(root.captureMode);
      if (currentIndex === -1) currentIndex = 0;
      
      currentIndex = (currentIndex + 1) % availableModes.length;
      root.captureMode = availableModes[currentIndex];
    }
    
    Keys.onLeftPressed: navigateLeft()
    Keys.onRightPressed: navigateRight()
    
    Keys.onPressed: (event) => {
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
    Keys.onEscapePressed: root.close()
    
    onVisibleChanged: if (visible) forceActiveFocus()
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
                Item {
                  Layout.alignment: Qt.AlignHCenter
                  width: 18
                  height: 16
                  readonly property color ic: root.captureMode === "region" ? root.accentColor : root.textColor
                  Rectangle {
                    x: 0
                    y: 0
                    width: 5
                    height: 2
                    color: parent.ic
                  }
                  Rectangle {
                    x: 0
                    y: 0
                    width: 2
                    height: 5
                    color: parent.ic
                  }
                  Rectangle {
                    x: 13
                    y: 0
                    width: 5
                    height: 2
                    color: parent.ic
                  }
                  Rectangle {
                    x: 16
                    y: 0
                    width: 2
                    height: 5
                    color: parent.ic
                  }
                  Rectangle {
                    x: 0
                    y: 14
                    width: 5
                    height: 2
                    color: parent.ic
                  }
                  Rectangle {
                    x: 0
                    y: 11
                    width: 2
                    height: 5
                    color: parent.ic
                  }
                  Rectangle {
                    x: 13
                    y: 14
                    width: 5
                    height: 2
                    color: parent.ic
                  }
                  Rectangle {
                    x: 16
                    y: 11
                    width: 2
                    height: 5
                    color: parent.ic
                  }
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
                Item {
                  Layout.alignment: Qt.AlignHCenter
                  width: 18
                  height: 15
                  readonly property color ic: (root.captureMode === "window" && root.isScreenshotMode) ? root.accentColor : root.textColor
                  readonly property color bar: (root.captureMode === "window" && root.isScreenshotMode) ? root.accentColor : root.textMuted
                  Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: parent.ic
                  }
                  Rectangle {
                    x: 1.5
                    y: 1.5
                    width: 15
                    height: 4
                    color: parent.bar
                    radius: 1
                  }
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
                Item {
                  Layout.alignment: Qt.AlignHCenter
                  width: 20
                  height: 17
                  readonly property color ic: root.captureMode === "screen" ? root.accentColor : root.textColor
                  readonly property color st: root.captureMode === "screen" ? root.accentColor : root.textMuted
                  Rectangle {
                    x: 0
                    y: 0
                    width: 20
                    height: 13
                    radius: 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: parent.ic
                  }
                  Rectangle {
                    x: 8.5
                    y: 13
                    width: 3
                    height: 2
                    color: parent.st
                  }
                  Rectangle {
                    x: 5
                    y: 15
                    width: 10
                    height: 2
                    radius: 1
                    color: parent.st
                  }
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

            Rectangle {
              Layout.fillWidth: true
              height: 36
              radius: 8
              color: root.accentColor

              RowLayout {
                anchors.centerIn: parent
                spacing: 7

                Item {
                  width: 14
                  height: 14
                  visible: root.captureMode === "region" && !root.isRegionSelected
                  Rectangle {
                    x: 0
                    y: 0
                    width: 4
                    height: 2
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 0
                    y: 0
                    width: 2
                    height: 4
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 10
                    y: 0
                    width: 4
                    height: 2
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 12
                    y: 0
                    width: 2
                    height: 4
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 0
                    y: 12
                    width: 4
                    height: 2
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 0
                    y: 10
                    width: 2
                    height: 4
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 10
                    y: 12
                    width: 4
                    height: 2
                    color: root.bgColor
                  }
                  Rectangle {
                    x: 12
                    y: 10
                    width: 2
                    height: 4
                    color: root.bgColor
                  }
                  Rectangle {
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 1.5
                    color: root.bgColor
                  }
                }

                Item {
                  width: 16
                  height: 13
                  visible: root.isScreenshotMode && !(root.captureMode === "region" && !root.isRegionSelected)
                  Rectangle {
                    x: 0
                    y: 3
                    width: 16
                    height: 10
                    radius: 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.bgColor
                  }
                  Rectangle {
                    x: 5
                    y: 0
                    width: 6
                    height: 4
                    radius: 1
                    color: root.accentColor
                    border.width: 1.5
                    border.color: root.bgColor
                  }
                  Rectangle {
                    x: 5
                    y: 5
                    width: 6
                    height: 6
                    radius: 3
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.bgColor
                  }
                }

                Rectangle {
                  width: 10
                  height: 10
                  radius: 5
                  color: root.bgColor
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

            Rectangle {
              width: 36
              height: 36
              radius: 8
              visible: root.isScreenshotMode
              color: root.includePointer ? root.accentBg(true) : root.surfaceColor
              border.width: root.includePointer ? 1 : 0
              border.color: root.ssAccent

              Shape {
                id: miniCursor
                anchors.centerIn: parent
                width: 10
                height: 14

                readonly property color ic: root.includePointer ? root.ssAccent : root.textMuted

                ShapePath {
                  fillColor: miniCursor.ic
                  strokeColor: miniCursor.ic
                  strokeWidth: 0.5
                  capStyle: ShapePath.RoundCap
                  joinStyle: ShapePath.MiterJoin

                  startX: 0
                  startY: 0
                  PathLine {
                    x: 0
                    y: 12
                  }
                  PathLine {
                    x: 3
                    y: 9.5
                  }
                  PathLine {
                    x: 5.5
                    y: 14
                  }
                  PathLine {
                    x: 7
                    y: 13
                  }
                  PathLine {
                    x: 4.5
                    y: 9
                  }
                  PathLine {
                    x: 8.5
                    y: 8.5
                  }
                  PathLine {
                    x: 0
                    y: 0
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.includePointer = !root.includePointer
              }
            }
          }
        }
      }
    }
  }
}
