pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    // Screen center expressed in root coordinates (parent is the EntryWrapper,
    // a direct child of the bar RowLayout, so parent.x is bar-relative)
    readonly property real screenCenterX: bar.width / 2 - (parent?.x ?? 0)

    property Title current: text1

    clip: true
    width: parent?.width ?? implicitWidth
    implicitWidth: Math.max(icon.implicitWidth, current.implicitWidth)
    implicitHeight: icon.implicitHeight

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.bar.width / 2;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    Item {
        id: content

        x: root.screenCenterX - width / 2
        width: icon.width + Tokens.spacing.small + current.implicitWidth
        height: parent.height

        // Glide to the new center instead of jumping while titles crossfade
        Behavior on x {
            Anim {
                type: Anim.Emphasized
            }
        }

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left

            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: root.colour
        }

        Title {
            id: text1
        }

        Title {
            id: text2
        }
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: Math.max(0, root.width - icon.width - Tokens.spacing.small * 2)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    component Title: StyledText {
        id: text

        anchors.verticalCenter: icon.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Tokens.spacing.small

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
