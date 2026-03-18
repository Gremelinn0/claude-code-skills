# Claude Code Skills & Rules

> A collection of skills and rules I built to develop a SaaS app (SpeakApp) entirely with Claude Code.

These are the **global skills** I use across all my projects — reusable agents for design, architecture, debugging, documentation, testing, and more.

---

## What are Claude Code Skills?

Skills are reusable instruction sets that extend Claude Code's behavior. Each skill lives in its own folder with a `SKILL.md` file that tells Claude exactly what to do when invoked.

```
~/.claude/skills/
├── doc-audit/         → Check consistency across 4 sources (docs, code, settings, website)
├── doc-keeper/        → Auto-update all docs after every code change
├── launch-wisper/     → Kill + restart the app instantly after any code change
├── ui-ux-pro-max/     → Professional UI/UX design (50 styles, 21 palettes)
├── systematic-debugging/ → Step-by-step debugging methodology
└── ...
```

---

## My Post-Dev Pipeline

After every code change, this pipeline runs automatically:

```
Code modified
    → launch-wisper     (restart app immediately)
    → doc-keeper        (update all MD docs)
    → doc-audit         (check 4-source consistency)
    → run-tests         (run full test suite)
```

---

## Skills List

### Dev Workflow
| Skill | What it does |
|-------|-------------|
| `doc-keeper` | Updates all project docs after any code change (changelog, MEMORY.md, roadmap, todo) |
| `doc-audit` | Checks consistency between 4 sources: MD docs + code + settings + live website |
| `writing-plans` | Plans multi-step implementation before touching code |
| `executing-plans` | Executes implementation plans with review checkpoints |
| `systematic-debugging` | Step-by-step debugging methodology |
| `test-driven-development` | TDD — write tests before implementation |
| `verification-before-completion` | Verifies work is actually done before claiming success |
| `finishing-a-development-branch` | Guides merge/PR/cleanup when a branch is complete |
| `using-git-worktrees` | Isolated git worktrees for parallel feature work |
| `dispatching-parallel-agents` | Runs independent tasks in parallel sub-agents |
| `subagent-driven-development` | Dev via specialized sub-agents |
| `brainstorming` | Structured ideation and feature planning |

### Code Quality
| Skill | What it does |
|-------|-------------|
| `error-handling-patterns` | Circuit breakers, graceful degradation, error aggregation |
| `handling-errors` | Resilient app error strategies |
| `react-stable-callbacks` | `useLatest` hook — stable callbacks without stale closures |
| `receiving-code-review` | How to handle code review feedback properly |
| `requesting-code-review` | How to ask for a code review |

### UI/UX & Design
| Skill | What it does |
|-------|-------------|
| `ui-ux-pro-max` | 50 styles, 21 palettes, 50 font pairings, 9 stacks (React, Next.js, Vue, Svelte...) |
| `brand-identity` | Design tokens, guidelines, voice/tone |
| `infographic` | Generate infographics via Krea.ai image API |
| `scroll-stop-prompter` | AI image/video prompts for scroll-stopping content |

### Supabase
| Skill | What it does |
|-------|-------------|
| `supabase-expert` | Full Supabase architecture (DB + Edge Functions) |
| `supabase-database-architect` | PostgreSQL, RLS, migrations |
| `supabase-backend-architect` | Edge Functions, Hono, API design |

### Tools & Automation
| Skill | What it does |
|-------|-------------|
| `mcp-auto-discovery` | Auto-discover and suggest MCP servers |
| `using-superpowers` | Discover and use all available skills |
| `hunting-automation-resources` | Find automation blueprints and n8n/Make workflows |
| `importing-notebooks` | Sync NotebookLM notebooks |
| `writing-skills` | Create and edit new skills |
| `creating-skills` | Build skills for the Antigravity agent environment |

---

## How to use these skills

1. Copy the skills you want into `~/.claude/skills/`
2. Claude Code will automatically detect and load them
3. Invoke with `/skill-name` or describe your task — Claude picks the right skill

---

## About

Built while developing **SpeakApp** — a voice dictation desktop app (STT, TTS, AI vocal agent) built as a SaaS.

> Follow me on LinkedIn for more Claude Code tips and workflows.
