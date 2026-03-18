---
name: brainstorming
description: Refines rough ideas through questions, explores alternatives, and presents design in sections for validation before writing code. Use when the user wants to brainstorm, plan a new feature, or design an architecture.
---

# Brainstorming & Planning

**The Socratic Design Refinement Process**

This skill activates before writing code. Its purpose is to refine rough ideas, explore technical alternatives, and create a solid plan validated by the user.

## When to use this skill
- The user asks to brainstorm a new idea, feature, or tool.
- The user wants to design an architecture or database schema from scratch.
- The user provides an ambiguous prompt that requires planning before execution.

## Workflow

Follow this step-by-step process:

1. **Discovery & Questioning (The Socratic Method)**
   - Do NOT write code yet.
   - Ask clarifying questions about the user's constraints, scale, tech stack, and goals.
   - Limit questions to 2-3 at a time so as not to overwhelm the user.

2. **Explore Alternatives**
   - Present 2-3 high-level approaches to solving the problem.
   - Weigh the pros and cons (trade-offs) of each approach.
   - Wait for the user to make a decision or express a preference.

3. **Present Design in Sections**
   - Once an approach is chosen, step through the design logically (e.g., Data Layer, API Layer, UI Layer).
   - Validate each section before moving to the next.

4. **Document the Plan**
   - Finalize the approved architecture.
   - Save the design document to `PLAN.md` or a similarly named architectural reference file.
   - Only advance to coding once the plan is fully agreed upon.

## Rules & Heuristics
- **Code comes last:** Never jump straight to generating implementation code without verifying the plan.
- **Listen actively:** If the user points out a flaw in the reasoning, incorporate it and pivot immediately.
- **Think scalable but pragmatic:** Don't overengineer if the user is building a prototype, but don't underengineer if they ask for enterprise-grade.
- **Update the Master Ledger:** Make sure any decisions made are reflected in `PLAN.md` (specifically the Architecture section and Roadmap).
