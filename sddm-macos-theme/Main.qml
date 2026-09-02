import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1a1b26"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property bool loggingIn: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      root.loggingIn = false
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  // Blurred + darkened wallpaper (pre-rendered)
  Image {
    anchors.fill: parent
    source: "background.jpg"
    fillMode: Image.PreserveAspectCrop
  }

  Column {
    anchors.centerIn: parent
    spacing: 22

    Image {
      source: "avatar.png"
      width: 160
      height: 160
      sourceSize.width: 320
      sourceSize.height: 320
      fillMode: Image.PreserveAspectFit
      smooth: true
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
      text: root.currentUser
      color: "white"
      font.family: "Inter"
      font.pixelSize: 30
      font.weight: Font.DemiBold
      anchors.horizontalCenter: parent.horizontalCenter
    }

    // Glassy pill password field
    Rectangle {
      width: 320
      height: 46
      radius: 23
      color: "#30ffffff"
      border.color: root.loginFailed ? "#f7768e" : "#55ffffff"
      border.width: 1
      anchors.horizontalCenter: parent.horizontalCenter

      TextInput {
        id: password
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: "white"
        selectionColor: "#7aa2f7"
        selectedTextColor: "white"
        font.family: "Inter"
        font.pixelSize: 15
        clip: true
        focus: true
        enabled: !root.loggingIn

        Keys.onPressed: {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.loggingIn = true
            sddm.login(root.currentUser, password.text, root.sessionIndex)
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: password
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        visible: password.text.length === 0
        text: root.loggingIn ? "Logging in…" : (root.loginFailed ? "Incorrect password, try again" : "Enter Password")
        color: root.loginFailed ? "#f7768e" : "#99ffffff"
        font.family: "Inter"
        font.pixelSize: 15
        font.italic: root.loginFailed
        elide: Text.ElideRight
      }
    }

    Text {
      text: "Press Return to log in"
      color: "#80ffffff"
      font.family: "Inter"
      font.pixelSize: 13
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
