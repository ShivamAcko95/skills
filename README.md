# Health RCA Toolkit

Codex plugin and skill bundle for health, life, and retail incident investigation.

It installs two Codex skills:

- `health-alert-rca-debugger`
- `jira-health-root-cause`

## What It Does

`health-alert-rca-debugger` helps investigate Datadog, Slack, and on-call alerts by collecting alert facts, checking logs/APM evidence, mapping downstream services, finding code points, and producing a concise RCA.

`jira-health-root-cause` helps investigate health and life Jira issues by starting from Jira facts, resolving proposal/user/order/payment evidence, searching local repos, and reporting a confirmed or clearly marked root cause.

## Prerequisites

- Codex installed locally.
- `git`, `bash`, and `python3` available on the machine.
- Access to any internal systems needed by the skills, such as Jira, Datadog, local service repositories, or API credentials.

## Install From GitHub

Clone the repository:

```bash
git clone git@github.com:ShivamAcko95/skills.git
cd skills
```

Run the installer:

```bash
./install.sh
```

Restart Codex if the plugin or skills do not appear immediately.

## Install From Zip

Download `health-rca-toolkit.zip` from this repository.

Extract it:

```bash
unzip health-rca-toolkit.zip
```

Run the installer from the extracted repository root:

```bash
./install.sh
```

## What Gets Installed

The installer copies the plugin to:

```text
~/.codex/plugins/health-rca-toolkit
```

It also installs both skills directly into Codex skills:

```text
~/.codex/skills/health-alert-rca-debugger
~/.codex/skills/jira-health-root-cause
```

It creates or updates the local Codex marketplace file:

```text
~/.agents/plugins/marketplace.json
```

## Custom Install Paths

Override install locations with environment variables:

```bash
CODEX_PLUGIN_DIR=/path/to/plugins \
CODEX_SKILLS_DIR=/path/to/skills \
CODEX_MARKETPLACE_PATH=/path/to/marketplace.json \
./install.sh
```

## Verify Installation

Check that the skill files exist:

```bash
ls ~/.codex/skills/health-alert-rca-debugger/SKILL.md
ls ~/.codex/skills/jira-health-root-cause/SKILL.md
```

If you have the Codex skill validator available, run:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/health-alert-rca-debugger
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/jira-health-root-cause
```

## Usage

In Codex, ask for the skill by name:

```text
Use health-alert-rca-debugger to investigate the latest health alert.
```

```text
Use jira-health-root-cause to debug this Jira issue: HEALTH-1234.
```

You can also describe the work naturally. Codex should select the skill when the request matches the skill description.

## Update

Pull the latest repository changes and rerun the installer:

```bash
git pull
./install.sh
```

The installer replaces the previously installed plugin and skill copies with the current repository version.

## Uninstall

Remove the installed plugin and skills:

```bash
rm -rf ~/.codex/plugins/health-rca-toolkit
rm -rf ~/.codex/skills/health-alert-rca-debugger
rm -rf ~/.codex/skills/jira-health-root-cause
```

If needed, remove the `health-rca-toolkit` entry from:

```text
~/.agents/plugins/marketplace.json
```

## Troubleshooting

If Codex does not show the skills after installation, restart Codex.

If `./install.sh` fails with permission errors, check that the user can write to:

```text
~/.codex
~/.agents
```

If GitHub clone fails, verify SSH access:

```bash
ssh -T git@github.com
```
