# plannotator

## Version Bumps

- The plugin (hooks + commands) comes from a shallow clone of the upstream
  repo at `~/.claude/plugins/marketplaces/plannotator/`.
- On version bump: delete the marketplace dir so make re-clones at the new tag:
  ```
  rm -rf ~/.claude/plugins/marketplaces/plannotator
  make -C plannotator
  ```
- Check if the set of slash commands has changed:
  ```
  gh api repos/backnotprop/plannotator/contents/apps/hook/commands --jq '.[].name'
  ```
