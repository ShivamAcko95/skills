# Health RCA Toolkit

Codex plugin containing two incident investigation skills:

- `health-alert-rca-debugger`
- `jira-health-root-cause`

## Install

Clone or download this repository, then run:

```bash
./install.sh
```

The installer copies the plugin to:

```text
~/.codex/plugins/health-rca-toolkit
```

It also creates or updates:

```text
~/.agents/plugins/marketplace.json
```

Restart Codex if the plugin does not appear immediately in the marketplace.

## Custom Paths

You can override the install locations:

```bash
CODEX_PLUGIN_DIR=/path/to/plugins \
CODEX_MARKETPLACE_PATH=/path/to/marketplace.json \
./install.sh
```

## Download Bundle

The downloadable archive is `health-rca-toolkit.zip`. Extract it, then run `./install.sh` from the extracted repository.
