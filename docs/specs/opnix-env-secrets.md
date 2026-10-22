# Spec: shared env secrets through opnix

## Problem Statement

API keys used by CLI tools (Anthropic, OpenAI, Gemini, Groq, Perplexity, Tavily, Kluster) have no managed home in the dotfiles. On the NixOS host they are declared as empty session variables, which exports a set-but-blank value that some tools treat as a real key. On the MacBook they are not declared at all. Every machine needs its keys pasted in by hand, nothing keeps two machines in agreement, and putting a real value into the Nix config would publish it to the world-readable store.

The user wants to declare each env value once, have every machine pick it up on rebuild, and bring up a new machine without copying secrets around.

## Solution

1Password stays the source of truth. The `Agents` 1Password vault holds the shared env values. The `Headless Agents` service account, which has read-only access to that vault, lets opnix fetch the values during Home Manager activation on both the MacBook and the NixOS host. Each value lands in its own owner-only file under the user's config directory. Fish exports every value at shell start by reading those files, so no secret value ever enters the Nix store.

The env values are declared in one registry, shared by both hosts. Adding a key means adding one line to the registry and one item to the vault, then rebuilding.

A new machine needs three steps: sign in to the 1Password app, run one bootstrap alias that stores the service account token locally, and rebuild.

## User Stories

1. As the dotfiles owner, I want to declare each env value once in a shared registry, so that every host gets the same set without duplicated config.
2. As the dotfiles owner, I want each registry entry to map an env var name to a 1Password reference, so that the config shows where every value comes from.
3. As the dotfiles owner, I want the values to live in the `Agents` vault, so that the service account can read them without touching my personal vault.
4. As the dotfiles owner, I want the service account limited to read-only on the `Agents` vault, so that a leaked token cannot change anything and exposes nothing outside that vault.
5. As the dotfiles owner, I want a rebuild on either host to fetch the latest values, so that rotating a key in 1Password reaches every machine without editing the repo.
6. As the dotfiles owner, I want no secret value in the Nix store, so that other users and processes on the machine cannot read keys through the store.
7. As the dotfiles owner, I want each fetched value written with owner-only permissions, so that only my user can read it.
8. As the dotfiles owner, I want fish to export every registered value at startup, so that CLIs in my terminal see the keys with no extra command.
9. As the dotfiles owner, I want fish to skip a value whose file is missing or empty instead of exporting an empty string, so that tools fall back to their own auth instead of failing on a blank key.
10. As the dotfiles owner, I want the existing empty API key session variables removed, so that blank keys stop shadowing real ones.
11. As the dotfiles owner, I want a bootstrap alias that copies the service account token from my personal vault (through the desktop `op` integration) into the local token file, so that a new machine never needs the token pasted by hand.
12. As the dotfiles owner, I want each host to name its own token item, so that I can later give a machine its own service account and revoke it without touching the others.
13. As the dotfiles owner, I want the bootstrap alias to be safe to run twice, so that rerunning it only refreshes the token.
14. As the dotfiles owner, I want the token file stored under my home directory with owner-only permissions, so that setup needs no sudo, no system daemon, and no extra group.
15. As the dotfiles owner, I want a rebuild without a token file to warn and keep going, so that the first rebuild of a new machine still links the rest of my home config.
16. As the dotfiles owner, I want a rebuild with an invalid or expired token to warn and keep the last fetched values, so that a 1Password problem never breaks my shell or blocks a switch.
17. As the dotfiles owner, I want rebuilds to report rate limiting clearly, so that I know whether stale values are a 1Password limit or a config mistake.
18. As the dotfiles owner, I want a host to be able to add host-only entries to the registry, so that a key needed on one machine doesn't spread to the other.
19. As the dotfiles owner, I want the MacBook and the NixOS host to use the same module, so that behavior is identical apart from paths the platform dictates.
20. As the dotfiles owner, I want a flake check that evaluates both hosts' home configs, so that I catch a broken registry before a rebuild.
21. As the dotfiles owner, I want the flake check to fail if any registry entry is missing its provisioned file, or its fish export unless the entry sets `export = false`, so that the three views of the registry cannot drift apart.
22. As the dotfiles owner, I want the flake check to fail if any API key appears in session variables again, so that the empty-key regression cannot return.
23. As the dotfiles owner, I want the flake check to fail if a registry reference points outside the `Agents` vault, so that the service account is never asked for a value it cannot read.
24. As the dotfiles owner, I want a `jn-` alias that reports which registered values are present in the current shell (names only, never values), so that I can confirm a machine after a switch.
25. As the dotfiles owner, I want the opnix input to follow my nixpkgs, so that it fits the existing input pattern and adds no second nixpkgs.
26. As the dotfiles owner, I want the opnix CLI available on both hosts, so that I can rerun a fetch or inspect the token by hand.
27. As a future maintainer of these dotfiles, I want the registry to be the only place that names env secrets, so that adding, renaming, or removing one is a single-line change.
28. As a future maintainer, I want the token location and the vault name defined once, so that rotating to a new service account touches one value.
29. As a future maintainer, I want the spec's known gaps (GUI apps, non-fish shells) written down, so that I don't mistake them for bugs.

## Implementation Decisions

- **New flake input.** `opnix` from `brizzbuzz/opnix`, pinned like the other inputs and following `nixpkgs`. Version at the time of writing is v0.11.0.
- **Home Manager module only.** Use `opnix.homeManagerModules.default` through a new shared module that both hosts import. Do not use the NixOS or nix-darwin system modules. All the secrets are per-user, so the system daemon, the root-owned token in `/etc`, and the `onepassword-secrets` group add setup cost with no benefit.
- **New shared module.** It is a noun-named module under the shared modules directory. It owns the registry option, the opnix configuration, the token path, and the vault name. It also owns its own fish wiring, the export and the `jn-secrets-check` function, so `terminal.nix` only imports it.
- **Registry shape.** A custom option `jn.secrets.entries` whose values are a string or `{ reference; export }`, mapping an env var name to an `op://<vault>/<item>/<field>` reference. The shared module sets the common entries. A host's home config can merge in its own. Every other view derives from this one attrset:
  - opnix `programs.onepassword-secrets.secrets`, one entry per env var, `kind = "field"`, mode `0600`, path under a dedicated secrets directory in the user's config dir, with the file named after the env var.
  - The fish export block.
  - The check alias's list of names.
- **Vault.** `Agents`, which already exists and holds 41 items. Its name is defined once in the shared module. The registry references only the items needed as env values. The initial entries cover the seven keys currently declared empty on the NixOS host, and each one must exist in `Agents` before it is registered. 1Password service accounts cannot read the built-in Personal or Private vault (from memory of 1Password's docs, not checked this session), which is why the values live in a separate vault.
- **Service account.** `Headless Agents`, with read-only access to `Agents` only. Its token is the `password` field of the item `Agents service account token` in `Agents`, so the bootstrap reads it as `op://Agents/Agents service account token/password` with the desktop-integrated `op` on a fresh machine. The service account can read that item too, so opnix can keep the token current once it runs.
- **Token item per host.** The token item reference is a per-host option that defaults to the shared `Agents service account token`. For now both hosts use the shared token. Giving a machine its own service account later means creating the account, saving its token as a new Personal item, and overriding the option in that host's home config. No module change is needed.
- **Token file.** It lives in the user's config directory with mode `0600`, and opnix `tokenFile` points at it. No sudo is involved.
- **Bootstrap alias.** A `jn-secrets-bootstrap` fish alias reads the token item with the desktop `op` and writes the token file with `umask 077`. It reuses the per-platform `op` path logic that the cliproxyapi module already has, hoisted to a shared helper so both modules use one definition.
- **Fish export.** It goes in fish shell init, not interactive-only init, so non-interactive fish scripts get the values too. For each registry name, it exports the file contents only when the file exists and has non-whitespace content. Values are read at shell start and never interpolated at build time.
- **Remove empty keys.** The seven empty `*_API_KEY` entries come out of the NixOS host's session variables.
- **Activation must not abort.** Upstream opnix's activation fragment calls `exit 0` when the token file is missing and `exit 1` when it is unreadable. HM concatenates activation fragments into one script, so either call can end the whole activation. The implementation must confirm where that fragment lands in the activation DAG relative to `linkGeneration`. If a missing or unreadable token can skip or fail the rest of activation, the shared module must make sure the fragment cannot end activation early. Possible fixes are guarding before it runs or overriding the fragment. The chosen fix gets a one-line comment explaining why.
- **Fetch timing.** Values refresh on every rebuild. There is no polling daemon and no separate refresh command. A rebuild is the refresh.
- **cliproxyapi's keys live in the registry.** Its proxy key and secret key are in `Agents` (`op://Agents/cliproxyapi/{proxy-key,secret-key}`) and registered as entries with `export = false`, so the provisioner fetches them but fish does not export them. An entry is a bare reference or `{ reference; export; }`, and `jn.secrets.files.<NAME>` is its absolute file path. The server config, the client routing script, and `jn-cpa-key` read those files, so the provisioner is the only caller of `op`. The proxy key is registered on both hosts and the secret key on the MacBook, where the server runs.
- **Flake check (approved new tooling).** Add a `checks` output for each system the hosts use. The check evaluates both host home configurations and fails when:
  - a registry entry has no provisioned file;
  - an entry without `export = false` is missing from the generated fish init;
  - any session variable name ends in `_API_KEY`;
  - a registry reference does not start with `op://Agents/`.
  Evaluating the other OS's configuration must stay eval-only so the check runs on either machine.

## Testing Decisions

- **What a good test asserts here.** It asserts what the user observes: the evaluated config a rebuild would apply, and the env a new shell has. It does not assert how opnix generates its JSON config or the order of activation fragments, except for the abort behavior above and the ordering consumers of the provisioned files depend on, which are observable.
- **Seam 1 is the flake check.** It is the evaluated home configuration of each host. It runs offline, needs no token, and never sees a secret value. It covers registry consistency, the API-key regression, and the vault prefix rule.
- **Seam 2 is the post-switch check.** After a real switch, a fresh fish shell runs the check alias and every registered name is present and non-empty. The alias prints names only. This is the only seam that proves the token, the vault permissions, and the fetch work end to end, so it runs on both hosts.
- **Failure-path checks on a real machine.** Rebuild once with the token file moved aside and confirm that activation completes, HM links are updated, and the last fetched values remain. Then rebuild once with a bogus token and confirm the same.
- **Prior art.** The repo has no flake checks yet, so this is the first. The cliproxyapi module's activation is the precedent for the warn-and-continue behavior in failure cases.

## Out of Scope

- System-level secrets, the NixOS or nix-darwin opnix daemons, and secret polling.
- Exporting the values to GUI apps launched by launchd or the desktop session.
- bash and zsh exports. fish is the shell this repo configures.
- Per-project or devshell secrets, and 1Password Environments.
- Automating creation of the vault or service accounts. Both are manual steps in 1Password.
- Creating per-machine service accounts now. The per-host token option keeps that a later, config-only change.
- Token rotation automation.

## Further Notes

- **Bootstrap order on a new machine.** Install from the flake, sign in to the 1Password desktop app with CLI integration on, run `jn-secrets-bootstrap`, then rebuild. The first rebuild before bootstrap is expected to warn and continue.
- **Already provisioned.** The `Agents` vault, the `Headless Agents` service account (read-only on `Agents`), and the item `Agents service account token`, moved from Personal into `Agents` on 2026-10-21. The token is not installed on any machine yet. The vault and service account were reported by the agent that created them. They were not checked again for this spec.
- **Blast radius.** `Agents` holds 41 items, more than the env values in the registry. A leaked token exposes every item in `Agents`, not just the registered ones. A narrower vault would limit that. This spec accepts the wider scope.
- **Tracer bullet.** The first slice exports `OP_SERVICE_ACCOUNT_TOKEN` on every machine. It is the first registry entry, and the desktop `op` provisions it at activation, so it needs no opnix. T3 Code captures its environment from the fish login shell, so the fish export reaches the agents it launches after a restart.
- **Field to settle during implementation.** The item and field names for each remaining env value.
- **Rate limits.** 1Password service accounts are rate-limited. Opnix reports this with exit status 75 (from opnix's best-practices doc). Seven values per rebuild is well under any limit, but the warning should stay visible.
- **Upstream source read for this spec.** opnix v0.11.0 (2026-08-18). Its HM module exposes `enable`, `tokenFile` (default `/etc/opnix-token`), `secrets.<name>.{reference, kind, path, owner, group, mode}`, `configFiles`, and a computed `secretPaths`. Relative paths resolve from the home directory.
