# Claude Code Skills Library

53 battle-tested skills for Claude Code — autonomous dev workflows, multi-agent orchestration, legal docs, content production, and more.

> Skills are markdown files that give Claude Code reusable, on-demand instructions. Drop them in `~/.claude/skills/` and invoke with `/skill-name`.

## Install

```bash
git clone https://github.com/Gremelinn0/claude-code-skills.git
cp -r claude-code-skills/skills/. ~/.claude/skills/
```

Or use the install script:

```bash
git clone https://github.com/Gremelinn0/claude-code-skills.git
cd claude-code-skills && bash install.sh
```

## Skills

### Dev Workflow
| Skill | Description |
|-------|-------------|
| `autopilot` | Goal-driven autonomous loop — runs until objective achieved via `/loop` + state.md |
| `drive` | Finish active session autonomously — take decisions alone, handoff to `/autopilot` |
| `executing-plans` | Load a written plan, execute in batches with architect review checkpoints |
| `finishing-a-development-branch` | Verify tests, present merge/PR options, handle chosen workflow |
| `subagent-driven-development` | Execute plan via fresh subagent per task + two-stage review |
| `systematic-debugging` | Find root cause before fixes — Phase 1 investigation always first |
| `verification-before-completion` | Run fresh verification commands, confirm output before claiming success |
| `test-driven-development` | Write test first, watch it fail, write minimal code to pass |
| `receiving-code-review` | Receive feedback technically — restate, verify, evaluate before implementing |
| `requesting-code-review` | Dispatch code-reviewer subagent to catch issues before cascade |

### Planning & Orchestration
| Skill | Description |
|-------|-------------|
| `dispatch` | Execute batch of independent micro-tasks in parallel with Opus review |
| `dispatching-parallel-agents` | Dispatch one agent per problem domain for concurrent investigation |
| `writing-plans` | Write comprehensive implementation plans — DRY, YAGNI, TDD, frequent commits |
| `plan` | Read PLAN_XXX.md, rewrite remaining work synthetically, push to Notion |
| `brainstorming` | Socratic design refinement — ask questions, explore alternatives before coding |

### Docs & Memory
| Skill | Description |
|-------|-------------|
| `doc-keeper` | Sync project docs AND skills after any code change — same commit, no exceptions |
| `doc-audit` | Verify coherence between memory files and code — detect orphans, drifted values |
| `migration-pickup` | Return to a session — git pull + read living plan |
| `wrapup` | End-of-session wrap-up — summarize, save memories, push to AI Brain |
| `wrapup-migration` | Wrap-up for account switch — sync living plan + force handoff + push Notion |
| `recap` | Instant session recap in human language — 30 seconds, no jargon |
| `sources-check` | Auto-inventory content sources BEFORE writing |
| `writing-skills` | Transform raw notes into clear readable text |

### Notion & Dashboards
| Skill | Description |
|-------|-------------|
| `notion-output` | Global skill for Notion output — URLs, videos, conclusions, dashboards |
| `dashboards-hub-master` | Deploy Vercel dashboards + maintain Master Hub for all projects |
| `auto-open-files` | Automatically open generated files in browser or app |
| `formation-consolider` | Consolidate raw training sources into main Notion page + sub-pages |

### AI Platform Tools
| Skill | Description |
|-------|-------------|
| `notebooklm` | Full API for Google NotebookLM — create notebooks, add sources, generate artifacts |
| `youtube-playlists-to-notebooklm` | Keep YouTube playlists synced with NotebookLM notebooks |
| `youtube-scraper` | Scrape YouTube — metadata, transcripts, comments |
| `skool-scraper` | Scrape Skool communities — lessons, files, descriptions, assets |
| `video-edit-auto` | Automated video editing — silence removal, animations via Descript/Auphonic |

### Legal
| Skill | Description |
|-------|-------------|
| `legal` | General legal document toolkit |
| `legal-nda` | NDA drafting and review |
| `legal-review` | Document review with risk analysis |
| `legal-risks` | Risk identification in contracts |
| `legal-terms` | Terms of service generation |
| `legal-privacy` | Privacy policy drafting |
| `legal-compliance` | Compliance audit |
| `legal-plain` | Translate legal text to plain language |
| `legal-negotiate` | Negotiation strategy for contracts |
| `legal-agreement` | General agreement drafting |
| `legal-compare` | Compare two versions of a legal document |
| `legal-freelancer` | Freelance contract templates |
| `legal-missing` | Identify missing clauses in contracts |
| `legal-report-pdf` | Generate legal reports as PDF |

### Design
| Skill | Description |
|-------|-------------|
| `claude-design-orchestrate` | End-to-end design orchestration on claude.ai/design |
| `claude-design-system-audit` | Audit Design System completeness — fonts, tokens, a11y |
| `infographic` | Generate professional infographics from text |

### Productivity & Automation
| Skill | Description |
|-------|-------------|
| `routine` | Create Claude Code routines — cloud or local, Opus default |
| `sync-claude-home` | Sync `~/.claude/` between machines via private git repo |
| `using-superpowers` | Invoke relevant skills BEFORE responding — 1% chance = must invoke |
| `computer-use-rules` | Strict rules for computer-use — screen selection, user window safety |

## Structure

```
skills/
  <skill-name>/
    SKILL.md      ← invoke with /skill-name in Claude Code
```

## License

MIT
