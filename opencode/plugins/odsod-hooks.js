export const OdsodHooks = async ({ $, directory }) => {
  return {
    "tool.execute.after": async (input, output) => {
      if (input.tool === "edit" || input.tool === "write" || input.tool === "apply_patch") {
        let filePath
        if (input.tool === "apply_patch") {
          const match = output.args.patchText?.match(
            /\*\*\* (?:Add|Update|Move to|Delete) File: (.+)/,
          )
          filePath = match?.[1]
        } else {
          filePath = output.args.filePath || output.args.path
        }
        if (filePath && /\.(md|yaml|yml|json|toml)$/.test(filePath)) {
          await $`oxfmt --write ${filePath}`.quiet().nothrow()
        }
      }
    },
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`test -d .jj && jj st > /dev/null 2>&1 || true`.quiet().nothrow()
      }
    },
  }
}
