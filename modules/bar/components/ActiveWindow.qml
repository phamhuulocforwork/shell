pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    required property var bar

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        return title;
    }

    readonly property int maxTextWidth: 420
    readonly property int hPad: Tokens.padding.normal
    readonly property int iconSize: Tokens.font.size.large

    implicitHeight: Tokens.sizes.bar.innerHeight
    implicitWidth: Math.max(iconSize + hPad * 2, row.implicitWidth + hPad * 2)
    radius: Tokens.rounding.full
    color: islandArea.containsMouse ? Colours.tPalette.m3surfaceContainer : Qt.alpha(Colours.tPalette.m3surfaceContainer, Colours.tPalette.m3surfaceContainer.a * 0.6)
    clip: true

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on color {
        CAnim {}
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: Colours.palette.m3primary
            font.pointSize: root.iconSize
        }

        StyledText {
            id: titleText

            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: root.maxTextWidth
            animate: true
            text: metrics.elidedText
            color: Colours.palette.m3primary
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.mono
            elide: Text.ElideRight
        }
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: titleText.font
        elide: Text.ElideRight
        elideWidth: root.maxTextWidth
    }

    MouseArea {
        id: islandArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            root.bar.islandHovered = true;
            root.bar.visibilities.dashboard = true;
        }

        onExited: {
            root.bar.islandHovered = false;
        }
    }
}
