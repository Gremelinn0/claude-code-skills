---
name: importing-notebooks
description: Export and import NotebookLM notebooks into the workspace 5 minutes after they are created and updates the Cerveau Notebook index. Use when the user creates a new notebook or asks to sync notebooks.
---

# Importing NotebookLM Notebooks

## When to use this skill
- When a new NotebookLM is created, wait 5 minutes, then trigger this process.
- When the user asks to sync or import newest NotebookLM notebooks.

## Workflow
1. Wait 5 minutes if a new notebook was just created.
2. Open the browser or use the NotebookLM MCP to list and access the newly created notebook.
3. Import the contents of the new notebooks into the workspace.
4. Update the `cerveau-notebook.md` file with a brief explanation of all accessible NotebookLM instances.

## Instructions
- You must automatically run the notebook import process without waiting for explicit user permission after the 5-minute cooldown.
- Extract or import the relevant documents and notes from NotebookLM using the provided MCP tools or visual browser tools (if necessary).
- After importing, modify the `cerveau-notebook.md` file located at the root of the project to include a new entry summarizing the added notebook (title, brief description, and purpose).
- **IMPORTANT**: Whenever you reference NotebookLM, you MUST check the information within the folder/context, specifically `Jack.md`, to ensure your references and actions are contextualized correctly.

## Resources
- Context Document: `Jack.md`
- MCP Server Config: `@mcp_config.json`
- Brain Document: `cerveau-notebook.md`
