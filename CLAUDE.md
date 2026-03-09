# CLAUDE.md - ApertureTokensManager

Application macOS pour importer, visualiser, filtrer et exporter des design tokens depuis Figma vers Xcode. Fonctionne avec le plugin Figma **ApertureExporter**.

Stack: SwiftUI + TCA + Swift Concurrency | macOS 14+

## Environment Adaptation

This project supports two Claude development environments:
- **Xcode 26.3+ Claude Agent SDK** - Uses Xcode built-in MCP tools
- **Pure Claude Code** - Uses command line Claude Code

Judge the current environment by checking `CLAUDE_CONFIG_DIR`:
- Contains `Xcode/CodingAssistant` -> Use [CLAUDE-XCODE.md](CLAUDE-XCODE.md)
- Otherwise -> Use [CLAUDE-PURE.md](CLAUDE-PURE.md)

## Documentation de reference

Consulte ces fichiers selon le besoin :
- [docs/architecture.md](docs/architecture.md) - Structure projet, features, conventions de nommage
- [docs/tca-patterns.md](docs/tca-patterns.md) - Reducer, 5 types d'actions, effects, navigation, checklist nouvelle feature
- [docs/client-service.md](docs/client-service.md) - Pattern Client/Service, @Shared, SharedKeys
- [docs/guidelines.md](docs/guidelines.md) - Regles, commandes build/test, skills de reference

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update 'tasks/lessons.md' with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -> then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan to 'tasks/todo.md' with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review to 'tasks/todo.md'
6. **Capture Lessons**: Update 'tasks/lessons.md' after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
