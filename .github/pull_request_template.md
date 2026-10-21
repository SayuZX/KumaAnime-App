## What changed
Describe the user-visible change and link the related issue, if any.

## Why
Explain the problem this change solves. Keep unrelated changes in a separate PR.

## Verification
List commands actually run and their results. Mark checks not run and explain why.

- Static analysis (`flutter analyze`):
- Relevant tests (`flutter test` or a focused test command):
- Device/emulator checks (platform, version, and steps):

For UI changes, attach before/after screenshots and check narrow layouts, dark
mode, text scaling, and accessibility where applicable. For playback changes,
state the source, playback scenario, and recovery behavior exercised.

## Risks and compatibility
Describe configuration changes, migrations, dependency changes, or known limits.
Write "None identified" only after reviewing the affected paths.

## Checklist
- [ ] This PR targets `master` and addresses one coherent change.
- [ ] Commit messages describe the actual changes in clear English.
- [ ] No credentials, signing keys, personal data, or generated build artifacts are included.
- [ ] Verification results above reflect checks actually performed.
- [ ] Documentation is updated where behavior or setup changes.
- [ ] Any co-author credit reflects a real contribution made with permission.
