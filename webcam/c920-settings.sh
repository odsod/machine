#!/bin/bash
DEV="$1"
v4l2-ctl -d "$DEV" --set-ctrl=focus_auto=0
v4l2-ctl -d "$DEV" --set-ctrl=focus_absolute=30
v4l2-ctl -d "$DEV" --set-ctrl=exposure_auto=1
v4l2-ctl -d "$DEV" --set-ctrl=exposure_absolute=166
v4l2-ctl -d "$DEV" --set-ctrl=white_balance_temperature_auto=0
v4l2-ctl -d "$DEV" --set-ctrl=white_balance_temperature=4500
v4l2-ctl -d "$DEV" --set-ctrl=backlight_compensation=0
v4l2-ctl -d "$DEV" --set-ctrl=power_line_frequency=1
v4l2-ctl -d "$DEV" --set-ctrl=gain=0
v4l2-ctl -d "$DEV" --set-ctrl=brightness=128
v4l2-ctl -d "$DEV" --set-ctrl=contrast=128
v4l2-ctl -d "$DEV" --set-ctrl=saturation=128
v4l2-ctl -d "$DEV" --set-ctrl=sharpness=128
v4l2-ctl -d "$DEV" --set-ctrl=zoom_absolute=100
