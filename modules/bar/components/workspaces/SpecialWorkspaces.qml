pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: monitor?.lastIpcObject.specialWorkspace?.name ?? ""

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.contentY > 0 ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.contentY < view.contentHeight - parent.height + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ListView {
        id: view

        readonly property real centeredSize: (currentItem as SpecialWsDelegate)?.size ?? 0

        anchors.fill: parent
        spacing: Tokens.spacing.medium
        interactive: false

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && w.monitor === root.monitor)
        }

        // Center the current delegate vertically instead of top-aligning at y=0
        preferredHighlightBegin: height / 2 - centeredSize / 2
        preferredHighlightEnd: height / 2 + centeredSize / 2
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            y: view.currentItem?.y ?? 0
            implicitHeight: (view.currentItem as SpecialWsDelegate)?.size ?? 0

            Behavior on y {
                Anim {}
            }
        }

        delegate: SpecialWsDelegate {}

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                type: Anim.StandardSmall
            }
            Anim {
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
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

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        asynchronous: true
        active: Config.bar.workspaces.activeIndicator
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.left: parent.left
                anchors.right: parent.right

                y: (view.currentItem?.y ?? 0) - view.contentY
                implicitHeight: (view.currentItem as SpecialWsDelegate)?.size ?? 0

                color: Colours.palette.m3tertiary
                radius: Tokens.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: parent.horizontalCenter

                    x: 0
                    y: -indicator.y
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on y {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        property real startY

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: Drag.YAxis
        drag.maximumY: 0
        drag.minimumY: Math.min(0, view.height - view.contentHeight - Tokens.padding.extraSmall)

        onPressed: event => startY = event.y

        onClicked: event => {
            if (Math.abs(event.y - startY) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y) as SpecialWsDelegate;
            if (ws?.modelData)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${ws.modelData.name.slice(8)}")` : `togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
        }
    }

    component SpecialWsDelegate: ColumnLayout {
        id: ws

        required property HyprlandWorkspace modelData
        readonly property int size: label.Layout.preferredHeight + (hasWindows ? windows.implicitHeight + Tokens.padding.extraSmall : 0)
        readonly property bool focused: root.activeSpecial === (modelData?.name ?? "")
        readonly property bool isOccupied: (modelData?.lastIpcObject.windows ?? 0) > 0
        readonly property string labelText: {
            const name = Hypr.trimWsName(ws.modelData?.name ?? "");
            const wsName = name.length > 0 ? name[0] : "";
            const capitalisation = Config.bar.workspaces.capitalisation;
            if (capitalisation === BarWorkspaceCapitalisation.Upper)
                return String(wsName).toUpperCase();
            if (capitalisation === BarWorkspaceCapitalisation.Lower)
                return String(wsName).toLowerCase();
            return wsName;
        }
        readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

        property int wsId
        property string icon
        property bool hasWindows

        function updateShape(): void {
            const shape = label.item as MaterialShape;
            if (!shape)
                return;

            if (focused)
                shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
            else
                shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
        }

        anchors.left: view.contentItem.left
        anchors.right: view.contentItem.right

        spacing: 0

        onFocusedChanged: updateShape()

        Component.onCompleted: {
            wsId = modelData.id;
            icon = Icons.matchIconRuleList(Hypr.trimWsName(modelData.name), GlobalConfig.bar.workspaces.specialWorkspaceIcons);
            hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
            updateShape();
        }

        // Hacky thing cause modelData gets destroyed before the remove anim finishes
        Connections {
            function onIdChanged(): void {
                if (ws.modelData)
                    ws.wsId = ws.modelData.id;
            }

            function onNameChanged(): void {
                if (ws.modelData)
                    ws.icon = Icons.matchIconRuleList(Hypr.trimWsName(ws.modelData.name), GlobalConfig.bar.workspaces.specialWorkspaceIcons);
            }

            function onLastIpcObjectChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: ws.modelData
        }

        Connections {
            function onShowWindowsOnSpecialWorkspacesChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: root.Config.bar.workspaces
        }

        Loader {
            id: label

            asynchronous: true

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

            sourceComponent: {
                const displayType = Config.bar.workspaces.specialDisplayType;
                if (displayType === BarWorkspaceDisplay.Text)
                    return labelComp;
                if (displayType === BarWorkspaceDisplay.Shapes)
                    return shapeComp;
                return iconLoaderComp;
            }

            onItemChanged: ws.updateShape()

            Component {
                id: shapeComp

                MaterialShape {
                    implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

                    color: Config.bar.workspaces.occupiedBg || ws.isOccupied || ws.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
                    scale: ws.focused ? 2 / 3 : ws.isOccupied ? 1 / 3 : 1 / 4

                    animationEasing: Tokens.anim.expressiveDefaultSpatial
                    animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

                    Behavior on color {
                        CAnim {}
                    }

                    Behavior on scale {
                        Anim {}
                    }
                }
            }

            Component {
                id: labelComp

                StyledText {
                    animate: true
                    text: ws.labelText
                    color: Config.bar.workspaces.occupiedBg || ws.isOccupied || ws.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
                    verticalAlignment: Qt.AlignVCenter
                    font.family: Tokens.font.workspaces
                }
            }

            Component {
                id: iconComponent

                MaterialIcon {
                    fill: 1
                    grade: 25
                    text: ws.icon
                    color: Config.bar.workspaces.occupiedBg || ws.isOccupied || ws.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
                    verticalAlignment: Qt.AlignVCenter
                }
            }

            Component {
                id: iconLoaderComp

                Loader {
                    sourceComponent: ws.icon ? iconComponent : labelComp
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.preferredHeight: implicitHeight

            visible: active
            active: ws.hasWindows

            sourceComponent: Column {
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
                            const windows = Hypr.toplevelsForWs(ws.wsId, GlobalConfig.bar.workspaces.ignoredTags);
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

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }
}
