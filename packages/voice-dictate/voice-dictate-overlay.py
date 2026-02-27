import os
import signal
import sys
import time

import objc
from AppKit import (
    NSEvent,
    NSApplication,
    NSApplicationActivationPolicyAccessory,
    NSBackingStoreBuffered,
    NSColor,
    NSFont,
    NSMakeRect,
    NSPanel,
    NSStatusWindowLevel,
    NSTextField,
    NSWindowCollectionBehaviorCanJoinAllSpaces,
    NSWindowCollectionBehaviorFullScreenAuxiliary,
    NSWindowStyleMaskBorderless,
)
from Foundation import NSObject, NSTimer
from PyObjCTools import AppHelper

STATE_FILE = os.environ["VOICE_DICTATE_STATE_FILE"]
PID_FILE = os.environ["VOICE_DICTATE_PID_FILE"]
WIDTH = 180.0
HEIGHT = 40.0


def cursor_position():
    point = NSEvent.mouseLocation()
    return float(point.x), float(point.y)


class OverlayController(NSObject):
    def init(self):
        self = objc.super(OverlayController, self).init()
        if self is None:
            return None
        self.state = "idle"
        self.frame = 0
        self.last_state_change = 0.0
        self.hidden_after = {"done": 1.2, "error": 1.6}
        self.window = None
        self.label = None
        self.setup_ui()
        return self

    @objc.python_method
    def setup_ui(self):
        x, y = cursor_position()
        panel = NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
            NSMakeRect(x + 14.0, y - 28.0, WIDTH, HEIGHT),
            NSWindowStyleMaskBorderless,
            NSBackingStoreBuffered,
            False,
        )
        panel.setLevel_(NSStatusWindowLevel)
        panel.setOpaque_(False)
        panel.setBackgroundColor_(NSColor.clearColor())
        panel.setHasShadow_(True)
        panel.setIgnoresMouseEvents_(True)
        panel.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces
            | NSWindowCollectionBehaviorFullScreenAuxiliary
        )

        bg = panel.contentView()
        bg.setWantsLayer_(True)
        bg.layer().setCornerRadius_(12.0)
        bg.layer().setBackgroundColor_(
            NSColor.colorWithCalibratedRed_green_blue_alpha_(0.08, 0.10, 0.16, 0.88).CGColor()
        )
        bg.layer().setBorderWidth_(1.0)
        bg.layer().setBorderColor_(
            NSColor.colorWithCalibratedRed_green_blue_alpha_(0.32, 0.36, 0.48, 0.9).CGColor()
        )

        label = NSTextField.alloc().initWithFrame_(NSMakeRect(12.0, 9.0, WIDTH - 24.0, 22.0))
        label.setEditable_(False)
        label.setBordered_(False)
        label.setDrawsBackground_(False)
        label.setTextColor_(NSColor.colorWithCalibratedRed_green_blue_alpha_(0.95, 0.96, 1.0, 1.0))
        label.setFont_(NSFont.monospacedSystemFontOfSize_weight_(14.0, 0.0))
        label.setStringValue_("Ready")
        bg.addSubview_(label)

        self.window = panel
        self.label = label

    @objc.python_method
    def apply_state(self, state):
        if state == self.state:
            return
        self.state = state
        self.frame = 0
        self.last_state_change = time.time()
        if state == "idle":
            self.window.orderOut_(None)
            return
        self.window.orderFrontRegardless()
        self.update_label()

    @objc.python_method
    def update_position(self):
        if self.state == "idle":
            return
        x, y = cursor_position()
        self.window.setFrame_display_(
            NSMakeRect(x + 14.0, y - 28.0, WIDTH, HEIGHT),
            True,
        )

    @objc.python_method
    def animate_text(self):
        spinner = ["◐", "◓", "◑", "◒"]
        pulse = ["●", "◉", "●", "◎"]
        if self.state == "listening":
            return f"{spinner[self.frame % 4]} Listening"
        if self.state == "recording":
            return f"{pulse[self.frame % 4]} Recording"
        if self.state == "transcribing":
            return f"{spinner[self.frame % 4]} Transcribing"
        if self.state == "done":
            return "✓ Done"
        if self.state == "error":
            return "! No speech"
        return ""

    @objc.python_method
    def update_label(self):
        self.label.setStringValue_(self.animate_text())

    def tick_(self, _timer):
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as fh:
                desired = fh.read().strip().lower() or "idle"
        except FileNotFoundError:
            desired = "idle"
        except Exception:
            desired = self.state

        self.apply_state(desired)
        self.update_position()

        if self.state in ("listening", "recording", "transcribing"):
            self.frame += 1
            self.update_label()
        elif self.state in self.hidden_after:
            if time.time() - self.last_state_change >= self.hidden_after[self.state]:
                self.apply_state("idle")


def main():
    app = NSApplication.sharedApplication()
    app.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

    controller = OverlayController.alloc().init()
    controller.apply_state("idle")

    def on_signal(signum, frame):
        try:
            os.unlink(PID_FILE)
        except OSError:
            pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    with open(PID_FILE, "w", encoding="utf-8") as fh:
        fh.write(str(os.getpid()))

    NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
        0.09, controller, "tick:", None, True
    )
    AppHelper.runEventLoop()


if __name__ == "__main__":
    main()
