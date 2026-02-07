# Agent Instructions

This repository automates the setup of a developer environment. It uses GNU Make to manage dependencies and installation logic.

## Repository Structure

- **Root Makefile**: Entry point. Installs system packages (dnf, flatpak) and iterates through subdirectories to install modular tools.
- **Tool Directories**: (e.g., `go/`, `buf/`) Contain specific Makefiles for downloading and installing individual tools.

## Version Management

We rely on agents to keep tool versions up-to-date.

### How to Update a Tool

1.  **Check for Updates**:
    - Open the tool's `Makefile`.
    - Look for the `version` variable.
    - Use the URL in the comment next to the version (e.g., `# https://github.com/.../releases`) to check for a newer version.
    - *If the URL is missing, please find the official release page and add it as a comment for future reference.*

2.  **Apply the Update**:
    - Change the `version` value to the new version number.
    - Ensure the `archive_url` will construct a valid download link.

3.  **Verify**:
    - Run the make command for that directory to verify the download works: `make -C <tool_directory>`.

4.  **Commit**:
    - **One commit per tool**.
    - **Format**: `feat(<directory_name>): bump to v<new_version>`
    - **Example**: `feat(buf): bump to v1.65.0`

## Conventions

- **Idempotency**: Makefiles should be idempotent.
- **Isolation**: Tools should ideally be installed into `~/.local/` or `build/` directories within the repo, avoiding global system changes where possible (except for the root system package installation).

## Maintaining This File

- **Updates**: When repository conventions change (e.g., new folder structure, new build system), update this file immediately.
- **Structure**:
    - Use clear, hierarchical Markdown headers.
    - Provide actionable, step-by-step instructions for common tasks (like version bumps).
    - Include specific examples for commit messages and file paths.
- **Writing Style**:
    - **Concise & Direct**: Use a professional, direct tone suitable for a CLI environment. Avoid conversational filler.
    - **Action-Oriented**: Focus on "how-to" and clear requirements.
    - **Precision**: Use exact file paths and variable names when providing instructions.
- **Goal**: Keep this file as the source of truth for autonomous agents.
- **Commit Format**: `docs: update AGENTS.md`
    - **Amending**: If you make small tweaks immediately after a commit, use `git commit --amend` to update the previous commit rather than creating a chain of small "fix" commits.