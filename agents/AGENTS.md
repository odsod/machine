# Global Agent Instructions

Agents must follow these instructions in all projects.

## Writing style

- **Headers + bullets** - No paragraphs
- **Code blocks** - For commands and templates
- **Reference, don't duplicate** - Point to skills: "Use `db-migrate` skill. See `.agents/skills/db-migrate/SKILL.md`"
- **No filler** - No intros, conclusions, or pleasantries
- **Trust capabilities** - Omit obvious context

### Anti-Patterns

Omit these:
- "Welcome to..." or "This document explains..."
- "You should..." or "Remember to..."
- Content duplicated from skills (reference instead)
- Obvious instructions ("run tests", "write clean code")
- Explanations of why (just say what)
- Long prose paragraphs

## Version Control

**CRITICAL:** Never interact with remote repositories. Ask the user.

### Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

- Keep all lines under 80 characters in width.

### Subject line

- Subject line must not be longer than 60 characters (one line in Github PR description).
- The subject line contains a succinct description of the change to the logic.

### Body

- Must be present tense
- Written in the imperative
- First letter is not capitalized
- Does not end with a '.'

## Gemini Added Memories

- Do not add memories unless specifically instructed by the user.
