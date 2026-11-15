// Add the workspace's .linear-context.md to the system prompt.
// Runs the shared session-start hook once per session and caches its output.
import { execFileSync } from "node:child_process";
import { homedir } from "node:os";

export default function (pi: any) {
  let context = "";
  pi.on("session_start", async () => {
    try {
      context = execFileSync(`${homedir()}/.agents/hooks/linear-context.sh`, [], {
        input: "",
        timeout: 20000,
      }).toString();
    } catch {
      context = "";
    }
  });
  pi.on("before_agent_start", async (event: any) => {
    if (!context) return;
    return { systemPrompt: `${event.systemPrompt}\n\n${context}` };
  });
}
