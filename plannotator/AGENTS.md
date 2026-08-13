# plannotator

## Version Bumps

- Binary: `"github:backnotprop/plannotator"` in root `mise.toml`.
- Wrappers in this directory are `[dotfiles]` shims onto the mise install.
- On version bump: update the `[tools]` pin, then `mise install` / `mise reshim`.
- Check if the set of slash commands has changed:
  ```
  gh api repos/backnotprop/plannotator/contents/apps/hook/commands --jq '.[].name'
  ```
