import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks"

export default function (pi: HookAPI): void {
  pi.on("tool_result", async (event) => {
    if (event.isError) return
    if (event.toolName !== "edit" && event.toolName !== "write") return

    const filePath = String(
      event.input?.file_path ?? event.input?.filePath ?? event.input?.path ?? "",
    )
    if (!filePath) return
    if (!/\.(md|yaml|yml|json|toml)$/.test(filePath)) return

    await pi.exec(`oxfmt --write "${filePath}"`)
  })

  pi.on("turn_end", async () => {
    await pi.exec("test -d .jj && jj st > /dev/null 2>&1 || true")
  })
}
