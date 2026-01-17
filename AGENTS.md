# AGENTS

## Scope
- Applies to the entire repository.
- Repo is a Nix flake for NixOS + nix-darwin + home-manager.
- Primary languages: Nix, shell (bash/zsh/fish).
- Keep changes minimal and consistent with existing module patterns.
- Respect OS-specific config differences under `hosts/`.

## Repo map
- `flake.nix` defines inputs and system outputs.
- `hosts/nixos/` contains NixOS system + home configs.
- `hosts/mbp/` contains macOS (nix-darwin) configs.
- `modules/` contains shared home-manager modules.
- `legacy/` holds shell scripts and config snippets.
- `modules/hyprland.nix` manages Wayland configuration.
- `modules/terminal.nix` owns shell and tmux setup.

## Build / apply (system)
- List flake outputs: `nix flake show`.
- Update inputs: `nix flake update --flake .`.
- NixOS apply: `sudo nixos-rebuild switch --flake .#nixos-jackcres`.
- NixOS build only: `nixos-rebuild build --flake .#nixos-jackcres`.
- macOS apply: `darwin-rebuild switch --flake .#Omars-MacBook-Pro`.
- macOS build only: `darwin-rebuild build --flake .#Omars-MacBook-Pro`.
- Home Manager is integrated into the rebuilds above.

## Checks / tests
- Run all flake checks: `nix flake check`.
- More verbosity: `nix flake check --show-trace --keep-going`.
- Single check: `nix build .#checks.<system>.<check-name>`.
- Discover check names: `nix flake show --all-systems`.
- If no checks exist, there are no automated tests.

## Lint / formatting
- No formatter configured in `flake.nix`.
- Do not add a formatter unless requested.
- Format manually using existing 2-space indentation.
- Keep list items one per line for readability.
- Avoid reflowing unrelated sections.

## Nix style guidelines
- Use 2-space indentation; no tabs.
- Curly braces stay on the same line as declarations.
- Terminate attributes with semicolons.
- Multiline module args use one item per line.
- Place `...` at the end of arg lists.
- Keep blank lines between logical blocks.
- Use `let ... in` for computed values.
- Prefer `inherit` to avoid repetition.
- Use `with pkgs;` only inside package lists.
- Keep `imports` near the bottom of each module.
- Keep `home.packages` and `programs.*` separated.
- Use double quotes for simple strings.
- Use Nix multiline strings `''` for long text.
- Avoid `builtins.trace` in committed changes.

## Module conventions
- Keep host-specific settings under `hosts/*/system.nix`.
- Keep user/home settings under `hosts/*/home.nix`.
- Shared, reusable config goes in `modules/`.
- Pass `inputs` via `_module.args` or `specialArgs`.
- Keep `environment.*` blocks grouped together.
- Use explicit `programs.<name>.enable = true` toggles.

## Naming conventions
- File names are lowercase with hyphens when needed.
- Output names are canonical: `nixos-jackcres`, `Omars-MacBook-Pro`.
- Module file names are nouns: `terminal.nix`, `development.nix`.
- Attribute names follow idiomatic Nix (lowerCamel or snake_case).
- Use `user` and `inputs` consistently in module args.
- Avoid single-letter variables unless in small lambdas.

## Imports / dependencies
- All external sources are pinned in `flake.nix`.
- When adding an input, follow the existing `follows` pattern.
- Keep input names short and descriptive.
- Do not introduce `fetchFromGitHub` in leaf modules.
- Prefer `inputs.<name>.packages.${system}` for external packages.

## Shell script guidelines
- Match the existing shebang (`#!/usr/bin/env bash` or `zsh`).
- Quote variables and paths to avoid globbing.
- Use `set -euo pipefail` in new scripts when safe.
- Print clear errors to stderr and exit non-zero.
- Keep functions small and named with verbs.
- Preserve current behavior when editing `legacy/` scripts.

## Fish/Zsh/Tmux configs
- Fish aliases live in `modules/terminal.nix`.
- Keep alias names descriptive and prefixed with `jn-`.
- Tmux scripts are sourced from `legacy/`.
- Avoid adding hard-coded absolute paths when possible.

## Error handling & safety
- Avoid destructive commands unless explicitly required.
- Prefer non-destructive rebuilds (`build`) before `switch`.
- When changing system packages, rebuild the appropriate target.
- Keep comments focused on intent, not mechanics.

## Optional maintenance commands
- Clean Nix store: `sudo nix-collect-garbage -d`.
- Update flake inputs: `nix flake update --flake .`.
- Rebuild after updates using the appropriate `*-rebuild`.
- Keep store clean before large refactors.

## Secrets & credentials
- API keys in `hosts/nixos/home.nix` are placeholders.
- Never commit secrets, tokens, or private keys.
- Prefer 1Password/SSH agent integrations already configured.
- Remove accidental secrets immediately if found.

## Validation checklist
- Run the relevant rebuild command after changes.
- Ensure `nix flake check` passes if checks exist.
- Confirm Home Manager settings apply as expected.
- Avoid modifying unrelated configuration blocks.

## Editing guidance
- Keep diffs focused and easy to review.
- Preserve list ordering unless there is a reason to sort.
- Add comments only when behavior is non-obvious.
- Do not introduce new tooling without approval.

## Cursor / Copilot rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found.
- If any are added later, summarize and mirror the rules here.

## Notes for agents
- This repo is personal dotfiles; be cautious with changes.
- Prefer asking before altering global defaults.
- Keep OS-specific changes in their respective host directories.
- When unsure, inspect `flake.nix` to confirm outputs.

## Single-test guidance (quick recap)
- Use `nix flake show --all-systems` to list checks.
- Build a specific check with `nix build .#checks.<system>.<name>`.
- If checks are absent, note that no single-test runner exists.

## Useful environment hints
- `JN_DOTFILES` is set in Home Manager configs.
- Default editor is `nvim`.
- `op-ssh-sign` is used for git signing.

## Final reminder
- Update this file if workflows or commands change.
- Keep guidance accurate and avoid speculation.

<!-- End of AGENTS.md -->
