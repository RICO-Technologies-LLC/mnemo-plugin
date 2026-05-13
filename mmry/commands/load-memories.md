Manually reload memories from the Mnemo API into your current context. This is equivalent to the automatic session-start load but can be run mid-session to refresh.

**Steps:**
1. Run the plugin's session-start bash script directly:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh"
```

2. Review the returned memories and integrate them into your current context.

For broader queries that include universal memories not loaded at startup, source the client library and call API functions directly — see the memory-system skill for full details on mid-session loading, scope-filtered queries, and search.
