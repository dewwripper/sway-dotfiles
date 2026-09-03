#!/usr/bin/env bash

# fcitx5-remote prints 1 when inactive/English, 2 when active/Vietnamese
STATE=$(fcitx5-remote 2>/dev/null)

if [ "$STATE" = "2" ]; then
    echo '{"text": "VN", "tooltip": "Vietnamese (Unikey)", "class": "vietnamese"}'
else
    echo '{"text": "EN", "tooltip": "English (US)", "class": "english"}'
fi
