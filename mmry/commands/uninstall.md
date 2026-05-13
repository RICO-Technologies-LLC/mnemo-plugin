Run the Mnemo uninstall script now:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup/uninstall.sh"
```

After the script completes, tell the user to run these two commands to finish removing the plugin, then restart Claude Code:

```
/plugin uninstall mnemo@mnemo-plugin
/plugin marketplace remove mnemo-plugin
```
