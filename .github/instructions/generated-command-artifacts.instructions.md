---
description: "Use when: adding or updating d365bap.tools PowerShell command functions."
applyTo: "d365bap.tools/functions/**/*.ps1"
---

# Generated Command Artifacts

- Do not manually create or update command documentation in `docs/` or Pester test files in `d365bap.tools/tests/functions/`.
- The project's generation pipeline creates command documentation and test files automatically.
- When adding a public command, update its implementation and the module manifest export list only; leave generated artifacts to the pipeline.