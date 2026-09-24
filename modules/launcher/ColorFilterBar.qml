pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Row {
    id: root

    readonly property real swatchSize: Tokens.padding.large * 2
    readonly property var colors: [
        {
            name: "",
            icon: "palette"
        },
        {
            name: "red",
            colour: "#F44336"
        },
        {
            name: "orange",
            colour: "#FF9800"
        },
        {
            name: "yellow",
            colour: "#FFEB3B"
        },
        {
            name: "green",
            colour: "#4CAF50"
        },
        {
            name: "blue",
            colour: "#2196F3"
        },
        {
            name: "purple",
            colour: "#9C27B0"
        },
        {
            name: "pink",
            colour: "#E91E63"
        },
        {
            name: "white",
            colour: "#FFFFFF"
        },
        {
            name: "black",
            colour: "#000000"
        }
    ]

    spacing: Tokens.spacing.extraSmall

    Repeater {
        model: root.colors

        delegate: StyledRect {
            id: swatch

            required property var modelData

            readonly property bool selected: Wallpapers.colorFilter === modelData.name
            readonly property bool isAll: modelData.name === ""
            readonly property bool needsOutline: modelData.name === "white" || modelData.name === "black"

            implicitWidth: root.swatchSize
            implicitHeight: root.swatchSize
            radius: width / 2
            color: "transparent"
            border.width: selected ? 2 : 0
            border.color: Colours.palette.m3primary

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: swatch.selected ? root.swatchSize - Tokens.padding.medium : root.swatchSize - Tokens.padding.small
                implicitHeight: implicitWidth
                radius: width / 2
                color: swatch.isAll ? Colours.palette.m3surfaceContainerHighest : swatch.modelData.colour
                border.width: swatch.needsOutline ? 1 : 0
                border.color: Colours.palette.m3outline

                MaterialIcon {
                    anchors.centerIn: parent

                    visible: swatch.isAll
                    text: swatch.modelData.icon
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StateLayer {
                radius: swatch.radius
                onClicked: Wallpapers.colorFilter = swatch.modelData.name
            }
        }
    }
}
