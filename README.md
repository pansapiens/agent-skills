# cursor/rules and AGENTS.md
My `.cursor/rules`, `.cursor/rules-caveman`, `AGENTS.md`, and `AGENTS.caveman.md` files.

- Edit the `.cursor/rules` directory to add/modify standard rules.

To generate the `AGENTS.md` and `AGENTS.caveman.md` files, run:
```
uv run generate_agents_md.py
```

## Caveman rules

`.cursor/rules-caveman` contains the caveman-compressed versions of `.cursor/rules`.

These are compiled to `AGENTS.caveman.md` by `generate_agents_md.py`.

When updating `.cursor/rules`, use the caveman (`caveman-compress`) skill to regenerate/edit the corresponding caveman rule.
