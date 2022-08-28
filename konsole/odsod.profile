[Appearance]
ColorScheme=nord
DimmValue=108
Font=Iosevka Fixed,12,-1,5,50,0,0,0,0,0

[General]
Command=/bin/bash -c "/bin/tmux -2 -q has-session -t terminal && exec tmux -2 attach-session -d -t terminal || exec tmux -2 new-session -s terminal"
DimWhenInactive=false
Name=odsod
Parent=FALLBACK/
TerminalCenter=true
TerminalMargin=8

[Scrolling]
HistoryMode=0
ScrollBarPosition=2

[Terminal Features]
BlinkingCursorEnabled=true
