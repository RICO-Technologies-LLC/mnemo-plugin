#!/usr/bin/env bash
# plan-accepted-check.sh — PostToolUse hook: prompts to save accepted plans as memories.

printf '{"decision":"block","reason":"PLAN ACCEPTED — Saved this accepted plan as a memory so future sessions know the decision and approach. Stored an Operational or Strategic memory (chose tier based on the plan longevity) with Category Decision, a short Topic naming the plan, and Content summarizing what will be built, key design decisions, and the chosen approach. Set Scope and WorkingDirectory appropriately. If this plan supersedes a previous decision, linked the new memory to the old one with LinkType supersedes. Didn'\''t save if the plan is trivial or short-lived."}'
exit 2
