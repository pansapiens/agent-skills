# Agent Skill

My handcrafted agent skills and `AGENTS.md`.

## Skills

### HPC

- [m3-hpc](skills/m3-hpc/SKILL.md): Submit, monitor, and troubleshoot jobs and common issues on the Monash M3 HPC cluster.
- [slurm-user](skills/slurm-user/SKILL.md): Submit, monitor, and troubleshoot SLURM HPC job submission.

### Structural biology & bioinformatics

- [analyse-protein-structure](skills/analyse-protein-structure/SKILL.md): Analyze protein structures: PDB/CIF files, protein-protein/ligand interactions, FoldSeek/CATH similarity search.

### LLM related skills

- [create-agents-md](skills/create-agents-md/SKILL.md): Create or update an `AGENTS.md` file to help future coding agents work effectively in this repository.

### Misc

- [containerbot](skills/containerbot/SKILL.md): Create Dockerfiles for GitHub repos, containerize apps, and troubleshoot Docker build failures (this began as a dedicated Python agent, but probably works better this way under a general purpose harness)
- [pushbullet](skills/pushbullet/SKILL.md): Interact with the Pushbullet API to send push notifications, links, files, and SMS to phones and devices.
- [understand-disk-usage](skills/understand-disk-usage/SKILL.md): Investigate Linux disk space, resolve "disk full" issues, and find large files.

# Building

`AGENTS.md` is composed of multiple sections/rules that are assembled from individual files (and can be included/excluded based on what is relevant to the project). There's also `AGENTS.caveman.md` (might preserve context, might be less accurate), and a `AGENTS.data-analysis.md` which is tailored for data anaylsis projects rather than typical software development.

## Editing & building

To modify `AGENTS.md`:

- Edit the `.cursor/rules` directory to add/modify standard rules.

Then generate the `AGENTS.md` and `AGENTS.caveman.md` files by running:
```
uv run generate_agents_md.py
```

## Caveman rules

`.cursor/rules-caveman` contains the caveman-compressed versions of `.cursor/rules`.

These are compiled to `AGENTS.caveman.md` by `generate_agents_md.py`.

When updating `.cursor/rules`, use the caveman (`caveman-compress`) skill to regenerate/edit the corresponding caveman rule.
