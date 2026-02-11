import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "msnap"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  signal selectionComplete(int x, int y, int width, int height)
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

  function confirmSelection() {
    if (hasSelection)
      selectionComplete(selX, selY, selW, selH);
  }

  Timer {
    id: defaultSelTimer
    interval: 1
    repeat: false
    onTriggered: {
      const p = root.contentItem;
      if (!p)
        return;
      const dw = 400, dh = 300;
      root.selX = Math.floor((p.width - dw) / 2);
      root.selY = Math.floor((p.height - dh) / 2);
      root.selW = dw;
      root.selH = dh;
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
                        root.confirmSelection();
                        event.accepted = true;
                      }
                    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      z: 0
    }

    Rectangle {
      x: root.selX
      y: root.selY
      width: root.selW
      height: root.selH
      visible: root.hasSelection
      color: "transparent"
      z: 1
    }

    Rectangle {
      x: 0
      y: 0
      width: overlay.width
      height: root.hasSelection ? root.selY : overlay.height
      color: Qt.rgba(0, 0, 0, 0.5)
      z: 2
      visible: root.hasSelection
    }
    Rectangle {
      x: 0
      y: root.hasSelection ? root.selY + root.selH : overlay.height
      width: overlay.width
      height: root.hasSelection ? overlay.height - (root.selY + root.selH) : 0
      color: Qt.rgba(0, 0, 0, 0.5)
      z: 2
      visible: root.hasSelection
    }
    Rectangle {
      x: 0
      y: root.selY
      width: root.hasSelection ? root.selX : 0
      height: root.selH
      color: Qt.rgba(0, 0, 0, 0.5)
      z: 2
      visible: root.hasSelection
    }
    Rectangle {
      x: root.selX + root.selW
      y: root.selY
      width: root.hasSelection ? overlay.width - (root.selX + root.selW) : 0
      height: root.selH
      color: Qt.rgba(0, 0, 0, 0.5)
      z: 2
      visible: root.hasSelection
    }

    Rectangle {
      x: root.selX
      y: root.selY
      width: root.selW
      height: root.selH
      visible: root.hasSelection
      color: "transparent"
      border.width: 2
      border.color: "#7aa2f7"
      z: 5
    }

    Rectangle {
      visible: root.hasSelection
      x: Math.min(Math.max(root.selX + 8, 8), overlay.width - width - 8)
      y: root.selY > 38 ? root.selY - 32 : root.selY + root.selH + 8
      width: dimText.implicitWidth + 16
      height: 24
      radius: 12
      color: Qt.rgba(0, 0, 0, 0.75)
      z: 10

      Text {
        id: dimText
        anchors.centerIn: parent
        text: root.selW + " × " + root.selH
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: "#ffffff"
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 20
      text: root.hasSelection ? "Drag to move  ·  Corners to resize  ·  Enter to confirm  ·  Esc to cancel" : "Drag to select  ·  Esc to cancel"
      font.pixelSize: 11
      color: Qt.rgba(1, 1, 1, 0.65)
      z: 10
    }

    Repeater {
      model: 4
      delegate: Rectangle {
        required property int index

        readonly property int hx: {
          if (index === 0 || index === 2)
            return root.selX;
          return root.selX + root.selW;
        }
        readonly property int hy: {
          if (index === 0 || index === 1)
            return root.selY;
          return root.selY + root.selH;
        }

        x: hx - 6
        y: hy - 6
        width: 12
        height: 12
        radius: 6
        visible: root.hasSelection && !root.isSelecting
        color: "#ffffff"
        border.width: 2
        border.color: "#7aa2f7"
        z: 12

        readonly property int diagCursor: (index === 0 || index === 3) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

        MouseArea {
          anchors {
            fill: parent
            margins: -6
          }
          cursorShape: parent.diagCursor
          hoverEnabled: true

          onPressed: mouse => {
                       root.isResizing = true;
                       root.activeHandle = parent.index;

                       if (parent.index === 0) {
                         root.resizeAnchorX = root.selX + root.selW;
                         root.resizeAnchorY = root.selY + root.selH;
                       } else if (parent.index === 1) {
                         root.resizeAnchorX = root.selX;
                         root.resizeAnchorY = root.selY + root.selH;
                       } else if (parent.index === 2) {
                         root.resizeAnchorX = root.selX + root.selW;
                         root.resizeAnchorY = root.selY;
                       } else {
                         root.resizeAnchorX = root.selX;
                         root.resizeAnchorY = root.selY;
                       }
                     }

          onPositionChanged: mouse => {
                               if (!root.isResizing || root.activeHandle !== parent.index)
                               return;

                               const pt = mapToItem(overlay, mouse.x, mouse.y);

                               const ax = root.resizeAnchorX;
                               const ay = root.resizeAnchorY;

                               const nx = Math.min(pt.x, ax);
                               const ny = Math.min(pt.y, ay);
                               const nw = Math.abs(pt.x - ax);
                               const nh = Math.abs(pt.y - ay);

                               if (nw >= 8 && nh >= 8) {
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
        if (root.hasSelection && mouseX >= root.selX && mouseX <= root.selX + root.selW && mouseY >= root.selY && mouseY <= root.selY + root.selH)
          return Qt.OpenHandCursor;
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
