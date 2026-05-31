import qs.services
import QtQuick
import qs.modules.onScreenDisplay

OsdValueIndicator {
    id: osdValues
    value: Audio.sink?.audio.volume ?? 0
    icon: Audio.sink?.audio.muted ? "volume_off" : "volume_up"
    name: Translation.tr("Volume")
    to: 1.5            // slider spans 0–150%
    warningThreshold: 1.0  // everything above 100% is drawn red
    warningColor: "#FF3B30"  // explicit vivid red (theme m3error blends into the peach fill)
}
