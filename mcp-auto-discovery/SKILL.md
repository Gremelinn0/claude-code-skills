---
name: Automatic MCP Discovery Rules
description: Core behavior to always search and suggest Model Context Protocol (MCP) servers when reaching technical limitations or when interacting with external platforms.
---

# Automatic MCP Discovery

## Context
As an AI agent, you must avoid creating complex, fragile workarounds (like using a browser_subagent or external webhooks) when interacting with popular SaaS or APIs. Your first reflex must always be to check if a dedicated Model Context Protocol (MCP) server exists for the target platform.

## Instructions
1. **Identify External Needs:** When the user asks to interact with an external service (e.g., Google Workspace, Slack, Jira, Stripe, Postgres), stop and evaluate.
2. **Check Connected MCPs:** Check your current list of initialized MCP servers. If the right one is connected, use it.
3. **If MCP is Missing:** If no relevant MCP is connected, **DO NOT invent a workaround**. 
   - Propose to the user to install the missing MCP server.
   - Example response: *"Je n'ai pas le serveur MCP [Name] d'installé pour accomplir ceci nativement. Veux-tu qu'on l'installe depuis la marketplace MCP (ou npm) avant de continuer ?"*
4. **Search Reference:** If needed, you can use a web search tool or point the user to community registries (like `smithery.ai` or MCP Github lists) to find the right server package.
5. **Wait for Installation:** Wait for the user to install and configure the MCP before proceeding with the task.
