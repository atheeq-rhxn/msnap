import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  readonly property real scaleFactor: screen ? screen.devicePixelRatio : 1.0

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "msnap"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  signal selectionComplete(int x, int y, int width, int height, bool quick)
  signal cancelled

  property bool isSelecting: false
  property bool isMoving: false
  property bool isResizing: false
  property int activeHandle: -1 // 0=TL 1=TR 2=BL 3=BR

  property int startX: 0
  property int startY: 0

  property int selX: 0
  property int selY: 0
  property int selW: 0
  property int selH: 0

  property int moveStartSelX: 0
  property int moveStartSelY: 0
  property int moveStartMouseX: 0
  property int moveStartMouseY: 0

  property int resizeAnchorX: 0
  property int resizeAnchorY: 0

  readonly property bool hasSelection: selW > 4 && selH > 4

  // Pre-calculated colors to avoid repeated Qt.rgba calls
  readonly property color overlayMask: Qt.rgba(Config.overlayColor.r, Config.overlayColor.g, Config.overlayColor.b, Config.overlayAlpha)

  readonly property color dimLabelBg: Qt.rgba(Config.dimLabelBg.r, Config.dimLabelBg.g, Config.dimLabelBg.b, Config.dimLabelAlpha)

  readonly property color instructionTextColor: Qt.rgba(Config.instructionColor.r, Config.instructionColor.g, Config.instructionColor.b, Config.instructionAlpha)

  // Handle positions data model
  readonly property var handlePositions: [
    {
      x: 0,
      y: 0,
      cursor: Qt.SizeFDiagCursor
    }  // TL
    ,
    {
      x: 1,
      y: 0,
      cursor: Qt.SizeBDiagCursor
    }  // TR
    ,
    {
      x: 0,
      y: 1,
      cursor: Qt.SizeBDiagCursor
    }  // BL
    ,
    {
      x: 1,
      y: 1,
      cursor: Qt.SizeFDiagCursor
    }   // BR
  ]

  // Resize anchor offsets (opposite corners)
  readonly property var anchorOffsets: [
    {
      x: 1,
      y: 1
    }  // TL: anchor at BR
    ,
    {
      x: 0,
      y: 1
    }  // TR: anchor at BL
    ,
    {
      x: 1,
      y: 0
    }  // BL: anchor at TR
    ,
    {
      x: 0,
      y: 0
    }   // BR: anchor at TL
  ]

  // Constants
  readonly property int defaultSelWidth: 400
  readonly property int defaultSelHeight: 300
  readonly property int handleSize: 12
  readonly property int handleHitArea: 6
  readonly property int minSelectionSize: 8

  function open() {
    isSelecting = false;
    isMoving = false;
    isResizing = false;
    activeHandle = -1;
    visible = true;
    defaultSelTimer.start();
  }

  function close() {
    visible = false;
    isSelecting = false;
    isMoving = false;
    isResizing = false;
    activeHandle = -1;
  }

  function confirmSelection(quick) {
    if (hasSelection) {
      selectionComplete(
        Math.round(selX * scaleFactor), 
        Math.round(selY * scaleFactor), 
        Math.round(selW * scaleFactor), 
        Math.round(selH * scaleFactor),
        quick
      );
    }
  }

  Timer {
    id: defaultSelTimer
    interval: 1  // Next event loop tick
    repeat: false
    onTriggered: {
      const p = root.contentItem;
      if (!p)
        return;

      root.selX = Math.floor((p.width - defaultSelWidth) / 2);
      root.selY = Math.floor((p.height - defaultSelHeight) / 2);
      root.selW = defaultSelWidth;
      root.selH = defaultSelHeight;
    }
  }

  Item {
    id: overlay
    anchors.fill: parent
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
                      if (event.key === Qt.Key_Escape) {
                        root.cancelled();
                        root.close();
                        event.accepted = true;
                      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        const isQuick = (event.modifiers & Qt.ShiftModifier) || Config.quickCapture;
                        root.confirmSelection(isQuick);
                        event.accepted = true;
                      }
                    }

    // Base overlay
    Rectangle {
      anchors.fill: parent
      color: root.overlayMask
      z: 0
    }

    // Transparent selection area
    Rectangle {
      x: root.selX
      y: root.selY
      width: root.selW
      height: root.selH
      visible: root.hasSelection
      color: "transparent"
      z: 1
    }

    // Top mask
    Rectangle {
      x: 0
      y: 0
      width: overlay.width
      height: root.hasSelection ? root.selY : overlay.height
      color: root.overlayMask
      z: 2
      visible: root.hasSelection
    }

    // Bottom mask
    Rectangle {
      x: 0
      y: root.hasSelection ? root.selY + root.selH : overlay.height
      width: overlay.width
      height: root.hasSelection ? overlay.height - (root.selY + root.selH) : 0
      color: root.overlayMask
      z: 2
      visible: root.hasSelection
    }

    // Left mask
    Rectangle {
      x: 0
      y: root.selY
      width: root.hasSelection ? root.selX : 0
      height: root.selH
      color: root.overlayMask
      z: 2
      visible: root.hasSelection
    }

    // Right mask
    Rectangle {
      x: root.selX + root.selW
      y: root.selY
      width: root.hasSelection ? overlay.width - (root.selX + root.selW) : 0
      height: root.selH
      color: root.overlayMask
      z: 2
      visible: root.hasSelection
    }

    // Selection border
    Rectangle {
      x: root.selX
      y: root.selY
      width: root.selW
      height: root.selH
      visible: root.hasSelection
      color: "transparent"
      border.width: 2
      border.color: Config.ssAccent
      z: 5
    }

    // Dimension label
    Rectangle {
      visible: root.hasSelection
      x: Math.min(Math.max(root.selX + 8, 8), overlay.width - width - 8)
      y: root.selY > 38 ? root.selY - 32 : root.selY + root.selH + 8
      width: dimText.implicitWidth + 16
      height: 24
      radius: 12
      color: root.dimLabelBg
      z: 10

      Text {
        id: dimText
        anchors.centerIn: parent
        text: Math.round(root.selW * root.scaleFactor) + " × " + Math.round(root.selH * root.scaleFactor) + " px"
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: Config.handleColor
      }
    }

    // Instructions
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 20
      text: root.hasSelection ? "Drag to move  ·  Corners to resize  ·  Enter to confirm  ·  Esc to cancel" : "Drag to select  ·  Esc to cancel"
      font.pixelSize: 11
      color: root.instructionTextColor
      z: 10
    }

    // Corner resize handles
    Repeater {
      model: root.handlePositions

      delegate: Rectangle {
        required property var modelData
        required property int index

        readonly property int hx: modelData.x === 0 ? root.selX : root.selX + root.selW
        readonly property int hy: modelData.y === 0 ? root.selY : root.selY + root.selH

        x: hx - root.handleSize / 2
        y: hy - root.handleSize / 2
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        visible: root.hasSelection && !root.isSelecting
        color: Config.handleColor
        border.width: 2
        border.color: Config.ssAccent
        z: 12

        MouseArea {
          anchors {
            fill: parent
            margins: -root.handleHitArea
          }
          cursorShape: modelData.cursor
          hoverEnabled: true

          onPressed: mouse => {
                       root.isResizing = true;
                       root.activeHandle = index;

                       const offset = root.anchorOffsets[index];
                       root.resizeAnchorX = root.selX + offset.x * root.selW;
                       root.resizeAnchorY = root.selY + offset.y * root.selH;
                     }

          onPositionChanged: mouse => {
                               if (!root.isResizing || root.activeHandle !== index)
                               return;

                               const pt = mapToItem(overlay, mouse.x, mouse.y);

                               const ax = root.resizeAnchorX;
                               const ay = root.resizeAnchorY;

                               const nx = Math.min(pt.x, ax);
                               const ny = Math.min(pt.y, ay);
                               const nw = Math.abs(pt.x - ax);
                               const nh = Math.abs(pt.y - ay);

                               if (nw >= root.minSelectionSize && nh >= root.minSelectionSize) {
                                 root.selX = nx;
                                 root.selY = ny;
                                 root.selW = nw;
                                 root.selH = nh;
                               }
                             }

          onReleased: {
            root.isResizing = false;
            root.activeHandle = -1;
          }
        }
      }
    }

    // Main interaction area
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      z: 3

      cursorShape: {
        if (root.isSelecting)
          return Qt.CrossCursor;
        if (root.isMoving)
          return Qt.ClosedHandCursor;
        if (root.hasSelection && mouseX >= root.selX && mouseX <= root.selX + root.selW && mouseY >= root.selY && mouseY <= root.selY + root.selH) {
          return Qt.OpenHandCursor;
        }
        return Qt.CrossCursor;
      }

      onClicked: mouse => {
                   if (mouse.button === Qt.RightButton) {
                     root.cancelled();
                     root.close();
                   }
                 }

      onPressed: mouse => {
                   if (mouse.button !== Qt.LeftButton || root.isResizing)
                   return;

                   const inSel = root.hasSelection && mouse.x >= root.selX && mouse.x <= root.selX + root.selW && mouse.y >= root.selY && mouse.y <= root.selY + root.selH;

                   if (inSel) {
                     root.isMoving = true;
                     root.moveStartSelX = root.selX;
                     root.moveStartSelY = root.selY;
                     root.moveStartMouseX = mouse.x;
                     root.moveStartMouseY = mouse.y;
                   } else {
                     root.isSelecting = true;
                     root.startX = mouse.x;
                     root.startY = mouse.y;
                     root.selX = mouse.x;
                     root.selY = mouse.y;
                     root.selW = 0;
                     root.selH = 0;
                   }
                 }

      onPositionChanged: mouse => {
                           if (root.isSelecting) {
                             root.selX = Math.min(mouse.x, root.startX);
                             root.selY = Math.min(mouse.y, root.startY);
                             root.selW = Math.abs(mouse.x - root.startX);
                             root.selH = Math.abs(mouse.y - root.startY);
                             return;
                           }

                           if (root.isMoving) {
                             const dx = mouse.x - root.moveStartMouseX;
                             const dy = mouse.y - root.moveStartMouseY;
                             const maxX = overlay.width - root.selW;
                             const maxY = overlay.height - root.selH;
                             root.selX = Math.max(0, Math.min(root.moveStartSelX + dx, maxX));
                             root.selY = Math.max(0, Math.min(root.moveStartSelY + dy, maxY));
                           }
                         }

      onReleased: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                      root.isSelecting = false;
                      root.isMoving = false;
                    }
                  }
    }
  }
}
