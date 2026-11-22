# The sidebar has no top row, so the spaces list starts at the top. Its buttons
# sit in a one-row footer as tall as the status bar beside it (28). The tab bar
# stays the window's drag area.
walk(
  if type == "object" and has("children") then
    .children |= map(
      select(.id != "brand")
      | if .id == "sidebar-footer" then .size.px = 28 else . end
    )
  else . end
)
