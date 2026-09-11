pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

RowLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    required property bool shouldShow

    required property Repeater workspaceRepeater
    required property real layoutSpacing

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitWidth + (hasWindows ? Tokens.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows && (Config.bar.workspaces.maxWindowIcons > 0)
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    readonly property real revealProgress: Math.max(0, Math.min(1, reveal))
    readonly property bool revealTransitionRunning: revealAnimation.running
    readonly property real precedingRevealProgress: {
        let progress = 0;

        for (let i = 0; i < index; ++i) {
            const workspace = workspaceRepeater.itemAt(i) as Workspace;
            if (workspace)
                progress = Math.max(progress, workspace.revealProgress);
        }

        return progress;
    }
    readonly property real targetX: {
        let offset = 0;

        for (let i = 0; i < index; ++i) {
            const workspace = workspaceRepeater.itemAt(i) as Workspace;
            if (workspace?.shouldShow)
                offset += workspace.size + layoutSpacing;
        }

        return offset;
    }

    property real reveal: shouldShow ? 1 : 0
    property real animatedSize: size

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: animatedSize * revealProgress
    Layout.leftMargin: layoutSpacing * Math.min(revealProgress, precedingRevealProgress)

    visible: shouldShow || revealProgress > 0
    opacity: revealProgress
    clip: true

    spacing: 0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Loader {
        id: indicator

        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        Layout.leftMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.spacing.small
        // Empty ws: force square cell (with margins) so the pill is a circle
        Layout.preferredWidth: root.hasWindows ? implicitWidth : Tokens.sizes.bar.innerWidth - Tokens.padding.extraSmall * 2 - Tokens.padding.small * 2

        onItemChanged: root.updateShape()
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        font.family: Tokens.font.workspaces
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.leftMargin: -Tokens.sizes.bar.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: Row {
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        const windows = Hypr.toplevelsForWs(root.ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on animatedSize {
        Anim {}
    }

    Behavior on reveal {
        Anim {
            id: revealAnimation

            type: Anim.DefaultEffects
        }
    }
}
