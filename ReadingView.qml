/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import QtWebKit 1.0
import MeeGo.Labs.Components 0.1
import MeeGo.App.Email 0.1

Item {
    id: container
    anchors.fill: parent
    parent: readingView.content
    
    property string uri;
    property bool downloadInProgress: false
    property bool openFlag: false
    property string saveLabel: qsTr("Save")
    property string openLabel: qsTr("Open")
    property string musicLabel: qsTr("Music")
    property string videoLabel: qsTr("Video")
    property string pictureLabel: qsTr("Picture")
    property string attachmentSavedLabel: qsTr("Attachment saved.")

    Connections {
        target: messageListModel
        onMessageDownloadCompleted: {
            scene.mailHtmlBody = messageListModel.htmlBody(scene.currentMessageIndex);
        }
    }
    Component {
        id: unsupportedFileFormat
        ModalDialog {
            leftButtonText: qsTr("")
            rightButtonText: qsTr("Ok")
            dialogTitle: qsTr ("")
            contentLoader.sourceComponent: DialogText {
                text: qsTr("File format is not supported.");
            }

            onDialogClicked: {
                dialogLoader.sourceComponent = undefined;
            }
        }
    }

    ContextMenu {
        id: attachmentContextMenu
        onTriggered: {
            if (index == 0)  // open attachment
            {
                openFlag = true;
                emailAgent.downloadAttachment(messageListModel.messageId(scene.currentMessageIndex), uri);
            }
            else if (index == 1) // Save attachment
            {
                openFlag = false;
                emailAgent.downloadAttachment(messageListModel.messageId(scene.currentMessageIndex), uri);
            }
        }
        Connections {
            target: emailAgent
            onAttachmentDownloadStarted: {
                downloadInProgress = true;
            }
            onAttachmentDownloadCompleted: {
                downloadInProgress = false;
                if (openFlag == true)
                {
                   var status = emailAgent.openAttachment(uri);
                   if (status == false)
                   {
                       showModalDialog(unsupportedFileFormat);
                   }
                }
            }
        }
    }  // end of attachmentContextMenu

    Rectangle {
        id: fromRect
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width
        height: 43
        Image {
            anchors.fill: parent
            fillMode: Image.Tile
            source: "image://theme/email/bg_email details_l"
        }
        Row {
            spacing: 5
            height: 43
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.topMargin: 1
            Text {
                width: subjectLabel.width
                font.pixelSize: theme_fontPixelSizeMedium
                text: qsTr("From:")
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
            }
            EmailAddress {
                anchors.verticalCenter: parent.verticalCenter
                added: false
                emailAddress: scene.mailSender
            }
        }
    }

    Rectangle {
        id: toRect
        anchors.top: fromRect.bottom
        anchors.topMargin: 1
        anchors.left: parent.left
        width: parent.width
        height: 43
        Image {
            anchors.fill: parent
            fillMode: Image.Tile
            source: "image://theme/email/bg_email details_l"
        }
        Row {
            spacing: 5
            height: 43
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 3
            Text {
                width: subjectLabel.width
                id: toLabel
                font.pixelSize: theme_fontPixelSizeMedium
                text: qsTr("To:")
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
            EmailAddress {
                //FIX ME: There is more then one mail Recipient
                anchors.verticalCenter: parent.verticalCenter
                emailAddress: mailRecipients[0]
            }
        }
    }

    Rectangle {
        id: subjectRect
        anchors.top: toRect.bottom
        anchors.left: parent.left
        width: parent.width
        anchors.topMargin: 1
        height: 43
        Image {
            anchors.fill: parent
            fillMode: Image.Tile
	    source: "image://theme/email/bg_email details_l"
        }
        Row {
            spacing: 5
            height: 43
            anchors.left: parent.left
            anchors.leftMargin: 3
            Text {
                id: subjectLabel
                font.pixelSize: theme_fontPixelSizeMedium
                text: qsTr("Subject:")
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.pixelSize: theme_fontPixelSizeLarge
                text: scene.mailSubject
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle {
        id: attachmentRect
        anchors.top: subjectRect.bottom
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.right: parent.right
        width: scene.content.width
        height: 41
        opacity: (scene.numberOfMailAttachments > 0) ? 1 : 0
        AttachmentView {
            height: parent.height
            width: parent.width
            model: mailAttachmentModel

            onAttachmentSelected: {
                container.uri = uri;
                attachmentContextMenu.model = [openLabel, saveLabel];
                attachmentContextMenu.menuX = mX;
                attachmentContextMenu.menuY = mY;
                attachmentContextMenu.visible = true;
            }
        }
    }
    Rectangle {
        id: bodyTextArea
        anchors.top: (scene.numberOfMailAttachments > 0) ? attachmentRect.bottom : subjectRect.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: downloadInProgress ? progressBarRect.top : previousNextEmailRect.top
        width: scene.content.width
        border.width: 1
        border.color: "black"
        color: "white"
        Flickable {
            id: flick
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 2
            width: parent.width
            height: parent.height
            contentWidth: {
                if (scene.mailHtmlBody == "") 
                    return edit.paintedWidth;
                else
                    return htmlViewer.width;
            }
            contentHeight:  {
                if (scene.mailHtmlBody == "") 
                    return edit.paintedHeight;
                else
                    return htmlViewer.height;
            }
            clip: true
         
            function ensureVisible(r)
            {
                if (contentX >= r.x)
                    contentX = r.x;
                else if (contentX+width <= r.x+r.width)
                    contentX = r.x+r.width-width;
                if (contentY >= r.y)
                    contentY = r.y;
                else if (contentY+height <= r.y+r.height)
                    contentY = r.y+r.height-height;
            }
            WebView {
                id: htmlViewer
                html: scene.mailHtmlBody
                transformOrigin: Item.TopLeft
                anchors.left: parent.left
                anchors.topMargin: 2
                preferredWidth: flick.width
                preferredHeight: flick.height
                settings.autoLoadImages: true
                contentsScale: 1
                focus: true
                clip: true
                opacity:  (scene.mailHtmlBody == "") ? 0 : 1
            }

            TextEdit {
                id: edit
                anchors.left: parent.left
                anchors.leftMargin: 5
                width: flick.width
                height: flick.height
                focus: true
                wrapMode: TextEdit.Wrap
                //textFormat: TextEdit.RichText
                font.pixelSize: theme_fontPixelSizeLarge
                readOnly: true
                onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                text: scene.mailBody
                opacity:  (scene.mailHtmlBody == "") ? 1 : 0
            }

/*            WebView {
                id: htmlViewer
                html: scene.mailHtmlBody
                transformOrigin: Item.TopLeft
                anchors.left: parent.left
                anchors.topMargin: 2
                preferredWidth: flick.width
                preferredHeight: flick.height
                settings.autoLoadImages: true
                contentsScale: 1
                focus: true
                clip: true
                opacity:  (scene.mailHtmlBody == "") ? 0 : 1
            } */
        }
    }

    BorderImage {
        id: progressBarRect
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: previousNextEmailRect.top
        opacity: downloadInProgress ? 1 : 0
        height: 45
        source: "image://theme/navigationBar_l"

        Item {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: downloadLabel.left
            anchors.bottom: parent.bottom
            height:parent.height
            Image {
                id: progressBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter:parent.verticalCenter
                fillMode: Image.Stretch
                source: "image://theme/playhead_bg"
            }
            Image {
                id: progressBarSlider
                anchors.verticalCenter:progressBar.verticalCenter
                source:"image://theme/scrub_head_sm"
                x: -width/2
                z:10
            }
            Image {
                id: elapsedHead
                source: "image://theme/media/progress_fill_1"
                anchors.left: progressBar.left
                anchors.verticalCenter:progressBar.verticalCenter
                z:1
            }
            BorderImage {
                id: elapsedBody
                source: "image://theme/media/progress_fill_2"
                anchors.left: elapsedHead.right
                anchors.right: elapsedTail.left
                anchors.verticalCenter:progressBar.verticalCenter
                border.left: 1; border.top: 1
                border.right: 1; border.bottom: 1
                z:1
            }
            Image {
                id: elapsedTail
                source: "image://theme/media/progress_fill_3"
                anchors.right: progressBarSlider.right
                anchors.rightMargin: progressBarSlider.width/2
                anchors.verticalCenter:progressBar.verticalCenter
                z:1
            }
            Connections {
                id: progressBarConnection
                target: emailAgent
                onProgressUpdate: {
                    progressBarSlider.x = percent * (progressBar.width - progressBarSlider.width) / 100 - progressBarSlider.width/2;
                }
            }
        }
        Text {
            id: downloadLabel
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            horizontalAlignment: Text.AlignLeft
            verticalAlignment:Text.AlignVCenter
            font.pixelSize: theme_fontPixelSizeLarge
            color: theme_fontColorMediaHighlight
            text: qsTr("Downloading...")
        }
    }
    Item {
        id: previousNextEmailRect
        anchors.bottom: readingViewToolbar.top
        anchors.left: parent.left
        anchors.right: parent.right
        width: scene.content.width
        height: previousEmailButton.height
        //color: "#0d0303"
    BorderImage {
        id: navigationBar
        width: parent.width
        source: "image://meegotheme/widgets/common/action-bar/action-bar-background"
    }

        ToolbarButton  {
            id: previousEmailButton
            anchors.left: parent.left
            anchors.top: parent.top
            visible: scene.currentMessageIndex > 0 ? true : false
            iconName: "mail-message-previous" 
            onClicked: {
                if (scene.currentMessageIndex > 0)
                {
                    scene.currentMessageIndex = scene.currentMessageIndex - 1;
                    scene.updateReadingView(scene.currentMessageIndex);
                }
            }
        }

        ToolbarButton {
            id: nextEmailButton

            anchors.right: parent.right
            anchors.top: parent.top
            visible: (scene.currentMessageIndex + 1) < messageListModel.messagesCount() ? true : false
            iconName: "mail-message-next" 

            onClicked: {
                if (scene.currentMessageIndex < messageListModel.messagesCount())
                {
                    scene.currentMessageIndex = scene.currentMessageIndex + 1;
                    scene.updateReadingView(scene.currentMessageIndex);
                }
            }
        }
    } 
    ReadingViewToolbar {
        id: readingViewToolbar
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: scene.content.width
    }
}
