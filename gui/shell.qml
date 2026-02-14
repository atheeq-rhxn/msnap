import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root
  component SmoothTransition: NumberAnimation {
    duration: 200
    easing.type: Easing.OutCubic
  }

  component ToggleButton: Rectangle {
    id: toggleRoot

    property string iconName: ""
    property bool active: false
    property color activeColor: Config.ssAccent
    property color inactiveColor: Config.textMuted
    property int iconSize: 20

    signal clicked

    width: Config.toggleButtonSize
    height: Config.toggleButtonSize
    radius: Config.defaultBorderRadius

    color: active ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.13) : Config.surfaceColor
    border.width: active ? 1 : 0
    border.color: activeColor

    Icon {
      anchors.centerIn: parent
      name: toggleRoot.iconName
      color: toggleRoot.active ? toggleRoot.activeColor : toggleRoot.inactiveColor
      size: toggleRoot.iconSize
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: toggleRoot.clicked()
    }
  }

  component CaptureModeButton: Rectangle {
    id: captureRoot

    property string mode: ""
    property string iconName: ""
    property string label: ""
    property bool isActive: false
    property bool isEnabled: true
    property color accentColor: Config.ssAccent
    property int iconSize: 20

    signal clicked

    Layout.fillWidth: true
    height: Config.buttonHeight
    radius: Config.defaultBorderRadius

    enabled: isEnabled
    opacity: isEnabled ? 1.0 : 0.3

    color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.13) : Config.surfaceColor
    border.width: isActive ? 1 : 0
    border.color: accentColor

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 5

      Icon {
        Layout.alignment: Qt.AlignHCenter
        name: captureRoot.iconName
        color: (captureRoot.isActive && captureRoot.isEnabled) ? captureRoot.accentColor : Config.textMuted
        size: captureRoot.iconSize
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: captureRoot.label
        font.pixelSize: 11
        font.weight: (captureRoot.isActive && captureRoot.isEnabled) ? Font.DemiBold : Font.Normal
        color: (captureRoot.isActive && captureRoot.isEnabled) ? captureRoot.accentColor : Config.textMuted
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: captureRoot.isEnabled
      cursorShape: captureRoot.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: captureRoot.clicked()
    }
  }

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

  // State properties
  property bool isScreenshotMode: true
  property string captureMode: "region"

  // Screenshot options
  property bool includePointer: false
  property bool includeAnnotation: false

  // Recording options
  property bool recordMic: false
  property bool recordAudio: false

  // Selection state
  property bool isRegionSelected: false
  property int selectedX: 0
  property int selectedY: 0
  property int selectedWidth: 0
  property int selectedHeight: 0
  property bool isRecordingActive: false

  // Computed properties
  readonly property color accentColor: isScreenshotMode ? Config.ssAccent : Config.recAccent
  readonly property var captureModes: ["region", "window", "screen"]

  property string freezeState: "idle"

  function enterFreeze() {
      if (freezeState !== "idle")
          return

      freezeState = "freezing"
      root.visible = false

      if (!wayfreezeProcess.running) {
          wayfreezeProcess.running = true
      }
  }

  function exitFreeze() {
      freezeState = "idle"
      root.visible = true
      mainContent.forceActiveFocus()
  }

  Process {
      id: wayfreezeProcess

      command: [
          "wayfreeze",
          "--enable-keyboard",
          "--after-freeze-cmd", "echo frozen"
      ]

      running: false

      stdout: SplitParser {
          onRead: data => {
              if (data.indexOf("frozen") !== -1) {
                  freezeState = "frozen"
                  root.visible = true
                  mainContent.forceActiveFocus()
              }
          }
      }

      onExited: (code, status) => {
          if (freezeState !== "idle") {
              exitFreeze()
          }
      }
  }

  Component.onCompleted: {
      if (isScreenshotMode) {
          enterFreeze();
      }
  }

  function accentBg(mode) {
    const c = mode ? Config.ssAccent : Config.recAccent;
    return Qt.rgba(c.r, c.g, c.b, 0.13);
  }

  onCaptureModeChanged: isRegionSelected = false

  onIsScreenshotModeChanged: {
    isRegionSelected = false;

    if (!isScreenshotMode && captureMode === "window") {
        captureMode = "region";
    }

    if (isScreenshotMode) {
        enterFreeze();
    } else {
        if (wayfreezeProcess.running)
            wayfreezeProcess.running = false;

        exitFreeze();
    }
  }

  FileView {
    id: recordingPidFile
    path: Config.pidFilePath
    watchChanges: true
    printErrors: false
    onLoaded: isRecordingActive = true
    onLoadFailed: {
      if (isRecordingActive) {
        isRecordingActive = false;
        if (!root.visible) {
          quitTimer.start();
        }
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
    wayfreezeProcess.running = false;
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

  function buildCommandArgs(baseCommand, isScreenshot) {
    const args = [Config[baseCommand + "Path"]];

    // Add geometry arguments
    if (captureMode === "region" && isRegionSelected) {
      args.push("-g", `${selectedX},${selectedY} ${selectedWidth}x${selectedHeight}`);
    } else if (captureMode === "window") {
      args.push("-w");
    }

    // Add mode-specific flags
    if (isScreenshot) {
      if (includePointer)
        args.push("-p");
      if (includeAnnotation)
        args.push("-a");
    } else {
      if (recordMic)
        args.push("-m");
      if (recordAudio)
        args.push("-a");
    }

    return args;
  }

  function executeScreenshot() {
    Quickshell.execDetached(buildCommandArgs("mshot", true));
    close();
  }

  function executeRecording() {
    const args = buildCommandArgs("mcast", false);
    args.push("--toggle");
    Quickshell.execDetached(args);
    isRecordingActive = true;
    root.visible = false;
  }

  function stopRecording() {
    Quickshell.execDetached([Config.mcastPath, "--toggle"]);
    isRecordingActive = false;
    if (!root.visible) {
      quitTimer.start();
    }
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
                           mainContent.forceActiveFocus();
                         }

    onCancelled: {
        root.visible = true;
        mainContent.forceActiveFocus();
    }
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
        color: Config.recAccent

        Behavior on width {
          SmoothTransition {}
        }
        Behavior on height {
          SmoothTransition {}
        }
        Behavior on radius {
          SmoothTransition {}
        }

        Rectangle {
          anchors.centerIn: parent
          width: 14
          height: 14
          radius: 2
          color: Config.bgColor
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
    id: mainContent
    anchors.fill: parent
    focus: true

    // Navigation helper functions
    function getAvailableModes() {
      return root.captureModes.filter(mode => mode !== "window" || root.isScreenshotMode);
    }

    function navigateMode(direction) {
      const availableModes = getAvailableModes();
      let currentIndex = availableModes.indexOf(root.captureMode);
      if (currentIndex === -1)
        currentIndex = 0;

      currentIndex = (currentIndex + direction + availableModes.length) % availableModes.length;
      root.captureMode = availableModes[currentIndex];
    }

    function toggleMode() {
      root.isScreenshotMode = !root.isScreenshotMode;
    }

    // Keyboard navigation
    Keys.onLeftPressed: navigateMode(-1)
    Keys.onRightPressed: navigateMode(1)

    // Key handler lookup table
    readonly property var keyHandlers: ({
                                          [Qt.Key_H]: () => navigateMode(-1),
                                          [Qt.Key_L]: () => navigateMode(1),
                                          [Qt.Key_J]: () => {
                                            root.isScreenshotMode = false;
                                          },
                                          [Qt.Key_K]: () => {
                                            root.isScreenshotMode = true;
                                          },
                                          [Qt.Key_P]: () => {
                                            if (root.isScreenshotMode) {
                                              root.includePointer = !root.includePointer;
                                            }
                                          },
                                          [Qt.Key_E]: () => {
                                            if (root.isScreenshotMode) {
                                              root.includeAnnotation = !root.includeAnnotation;
                                            }
                                          },
                                          [Qt.Key_M]: () => {
                                            if (!root.isScreenshotMode) {
                                              root.recordMic = !root.recordMic;
                                            }
                                          },
                                          [Qt.Key_A]: () => {
                                            if (!root.isScreenshotMode) {
                                              root.recordAudio = !root.recordAudio;
                                            }
                                          }
                                        })

    Keys.onPressed: event => {
                      const handler = keyHandlers[event.key];
                      if (handler) {
                        handler();
                        event.accepted = true;
                      }
                    }

    Keys.onTabPressed: toggleMode()
    Keys.onBacktabPressed: toggleMode()
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
        anchors.bottomMargin: Config.panelBottomMargin
        width: Config.panelWidth
        height: layout.implicitHeight + 26
        color: Config.bgColor
        radius: 12
        border.width: 1
        border.color: Config.borderColor

        MouseArea {
          anchors.fill: parent
          // Block clicks from propagating to parent
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

          // Mode selector (Screenshot / Record)
          Rectangle {
            Layout.fillWidth: true
            height: 34
            color: Config.surfaceColor
            radius: Config.defaultBorderRadius

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
                color: root.isScreenshotMode ? Config.ssAccent : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "Screenshot"
                  font.pixelSize: 12
                  font.weight: root.isScreenshotMode ? Font.DemiBold : Font.Normal
                  color: root.isScreenshotMode ? Config.bgColor : Config.textMuted
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
                color: !root.isScreenshotMode ? Config.recAccent : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "Record"
                  font.pixelSize: 12
                  font.weight: !root.isScreenshotMode ? Font.DemiBold : Font.Normal
                  color: !root.isScreenshotMode ? Config.bgColor : Config.textMuted
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.isScreenshotMode = false
                }
              }
            }
          }

          // Capture mode buttons
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.defaultSpacing

            CaptureModeButton {
              mode: "region"
              iconName: "crop"
              label: "Region"
              isActive: root.captureMode === "region"
              accentColor: root.accentColor
              onClicked: root.captureMode = "region"
            }

            CaptureModeButton {
              mode: "window"
              iconName: "app-window"
              label: "Window"
              isActive: root.captureMode === "window"
              isEnabled: root.isScreenshotMode
              accentColor: root.accentColor
              onClicked: root.captureMode = "window"
            }

            CaptureModeButton {
              mode: "screen"
              iconName: "device-desktop"
              label: "Screen"
              isActive: root.captureMode === "screen"
              accentColor: root.accentColor
              iconSize: 22
              onClicked: root.captureMode = "screen"
            }
          }

          // Selection dimensions display
          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.captureMode === "region" && root.isRegionSelected
            text: root.selectedWidth + " × " + root.selectedHeight
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: root.accentColor
          }

          // Action buttons row
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.defaultSpacing

            // Main action button
            Rectangle {
              Layout.fillWidth: true
              height: Config.toggleButtonSize
              radius: Config.defaultBorderRadius
              color: root.accentColor

              RowLayout {
                anchors.centerIn: parent
                spacing: 7

                Icon {
                  name: "crop"
                  color: Config.bgColor
                  size: 18
                  visible: root.captureMode === "region" && !root.isRegionSelected
                }

                Icon {
                  name: "camera"
                  color: Config.bgColor
                  size: 18
                  visible: root.isScreenshotMode && !(root.captureMode === "region" && !root.isRegionSelected)
                }

                Icon {
                  name: "player-record"
                  color: Config.bgColor
                  size: 16
                  visible: !root.isScreenshotMode && !(root.captureMode === "region" && !root.isRegionSelected)
                }

                Text {
                  text: {
                    if (root.captureMode === "region" && !root.isRegionSelected) {
                      return "Select Region";
                    }
                    return root.isScreenshotMode ? "Capture" : "Start Recording";
                  }
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  color: Config.bgColor
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.executeAction()
              }
            }

            // Screenshot mode toggles
            ToggleButton {
              iconName: "pencil"
              active: root.includeAnnotation
              activeColor: Config.ssAccent
              visible: root.isScreenshotMode
              onClicked: root.includeAnnotation = !root.includeAnnotation
            }

            ToggleButton {
              iconName: "mouse"
              active: root.includePointer
              activeColor: Config.ssAccent
              visible: root.isScreenshotMode
              onClicked: root.includePointer = !root.includePointer
            }

            // Recording mode toggles
            ToggleButton {
              iconName: "microphone"
              active: root.recordMic
              activeColor: Config.recAccent
              visible: !root.isScreenshotMode
              onClicked: root.recordMic = !root.recordMic
            }

            ToggleButton {
              iconName: "volume"
              active: root.recordAudio
              activeColor: Config.recAccent
              visible: !root.isScreenshotMode
              onClicked: root.recordAudio = !root.recordAudio
            }
          }
        }
      }
    }
  }
}
