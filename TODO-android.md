# TODO: declarative Android setup on MBP

Planning document only. No migration or cleanup has been performed by writing
this file. Android Studio is not required.

## Current setup (inspected 2026-09-19)

Host: `aarch64-darwin`, flake output `Omars-MacBook-Pro`.

The Android CLI was installed with Google's `darwin_arm64/install.sh` installer.
The manual launcher is `~/.local/bin/android`; related files exist under
`~/.android/bin/android-cli` and `~/.android/cli/`.

SDK root: `~/Library/Android/sdk`.

| Installed component | Version |
| --- | --- |
| `cmdline-tools/latest` | 23.0.0 |
| `emulator` | 37.1.11 |
| `platform-tools` | 37.0.1 |
| `system-images/android-36/google_apis_playstore/arm64-v8a` | revision 7 |

The command-line tools were installed after the initial T3 warning. No Android
platform SDK, build-tools, NDK, or CMake appeared in the installed package list.

`hosts/mbp/home.nix` currently sets `ANDROID_HOME` to the manual SDK and adds its
`emulator` and `platform-tools` directories to PATH.

The existing AVD is `medium_phone`, stored in `~/.android/avd/medium_phone.avd`
with its registration in `~/.android/avd/medium_phone.ini`. Important settings:

| Setting | Current value |
| --- | --- |
| Display name / AvdId | Medium Phone / Medium_Phone |
| Device profile | Generic `medium_phone` |
| Target / image | Android 36, Google Play, `arm64-v8a` |
| CPU / RAM | 4 cores / 2048 MiB |
| Display | 1080 × 2400, density 420 |
| Data partition / SD card | 6G / 512M |
| GPU | enabled, auto |
| Cameras | back: virtualscene; front: emulated |
| Keyboard / frame | enabled / shown |
| Boot | fast boot enabled |
| VM heap | 228 MiB |

Its `image.sysdir.1` currently uses the relative path
`system-images/android-36/google_apis_playstore/arm64-v8a/`.
Preserve the complete config before migration, including sensor settings not
listed above. `~/.android/adbkey` is a private device authorization key: preserve
it locally, never add it to Git.

## Intended ownership

- Nix owns the Android CLI, SDK tools, emulator binaries, system images, and
  their pinned versions.
- Home Manager owns environment variables, PATH, a declarative AVD specification,
  and an idempotent command or activation step to create the AVD.
- Emulator disks, installed apps, snapshots, locks, and ADB keys remain writable
  user state outside `/nix/store`. Declarative recreation means reproducing a
  fresh device with the same specification, not reproducing its live contents.
- SDK additions and updates happen through the flake. Do not run
  `android sdk install/update`, `sdkmanager --install`, or `android update`
  against the Nix-managed installation.

## Implementation checklist

- [ ] Add `modules/android.nix`, imported only from `hosts/mbp/home.nix` initially.
  Do not change the Linux host as part of this migration.
- [ ] Install `pkgs.android-cli`. The current pinned nixpkgs contains version
  `1.0.15498356` with Apple Silicon support; compare it with the manual CLI's
  `--version` before deciding whether a newer pin is necessary.
- [ ] Compose the SDK with `pkgs.androidenv.composeAndroidPackages`.
- [ ] Set `nixpkgs.config.android_sdk.accept_license = true` in the MBP system
  module after reviewing the SDK license. Home Manager uses global pkgs here,
  so do not attempt to configure a separate Home Manager nixpkgs instance.
- [ ] Check that the pinned Android repository metadata contains the exact
  versions below and image revision 7. If unavailable, document the difference
  and deliberately update the pin or add pinned repository metadata through
  the flake. Do not silently replace versions with an unverified `latest`.

Proposed composition, to evaluate and test before enabling:

```nix
android = pkgs.androidenv.composeAndroidPackages {
  cmdLineToolsVersion = "23.0";
  platformToolsVersion = "37.0.1";
  emulatorVersion = "37.1.11";
  includeEmulator = true;
  platformVersions = [ "36" ];
  includeSystemImages = true;
  systemImageTypes = [ "google_apis_playstore" ];
  abiVersions = [ "arm64-v8a" ];
  toolsVersion = null;
  buildToolsVersions = [ ];
  includeSources = false;
  includeNDK = false;
  includeCmake = false;
};
```

`platformVersions = [ "36" ]` also selects the Android 36 platform SDK, an
addition to the current emulator-only installation. This is a practical baseline
for composition; inspect the resulting closure and document that addition.
System-image revision selection comes from pinned repository metadata, rather
than a revision argument in this snippet. The snippet has not been built or
validated for exact version availability.

- [ ] Add `android.androidsdk` and `pkgs.android-cli` to `home.packages`.
- [ ] Replace the existing `androidSdk` value in `hosts/mbp/home.nix` with the
  composed SDK root (`${android.androidsdk}/libexec/android-sdk`), or move all
  Android settings into the new module. Avoid conflicting definitions.
- [ ] Set `ANDROID_HOME` to the final SDK root; if `ANDROID_SDK_ROOT` is retained
  for compatibility, set it to the same value.
- [ ] Include emulator, platform-tools, and command-line tools on PATH. Nix's
  SDK package exposes common executables in its `bin`; inspect their wrappers
  and Java dependencies rather than assuming a system Java installation.
- [ ] Inspect T3 compatibility: the installed T3 build explicitly checks
  `$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager`, as well as `adb` and
  `emulator` under that same root. A versioned command-line-tools directory alone
  may not satisfy it. If needed, build a Nix SDK facade that links the composed
  SDK directories and adds `cmdline-tools/latest` pointing at the actual tools
  version. Set `ANDROID_HOME` to the facade and test wrappers against it.
- [ ] Check for a persisted Android CLI SDK override and project `local.properties`
  files containing `sdk.dir`. Update only references to the old installation.

## Recreate the virtual device declaratively

- [ ] Save a sanitized copy of the current AVD specification in the repo, omitting
  machine-specific absolute paths. Keep the full original only in the local backup.
- [ ] Verify that the Nix `avdmanager list device` includes `medium_phone`.
- [ ] Implement a Home Manager activation step after `writeBoundary`, respecting
  activation dry-run behavior, or a packaged `jn-android-create-avd` command.
  Invoke the Nix-provided tool using an absolute store path, conceptually:

  ```sh
  avdmanager create avd \
    --name medium_phone \
    --package 'system-images;android-36;google_apis_playstore;arm64-v8a' \
    --device medium_phone
  ```

  Supply `no` on stdin if prompted for a custom hardware profile. Apply the
  recorded hardware overrides after creation, keeping `config.ini` writable.
  Never use `--force` on the existing device during normal activation.
- [ ] Make creation conditional on the AVD being absent. Repeated switches must
  preserve user data and avoid overwriting a running emulator's configuration.
- [ ] Handle updates separately: while the emulator is stopped, update only the
  managed config keys and image reference; avoid stale absolute store paths after
  a flake update or garbage collection. Keep the relative image path if verified
  to resolve through the new SDK correctly.
- [ ] Do not make the whole `.avd` directory or its live `config.ini` a read-only
  Home Manager symlink. The emulator writes state there.
- [ ] First validate a separate disposable AVD, then migrate `medium_phone`.
  Preserve its disks; if snapshot compatibility changes, try a cold boot without
  wiping data. Never use `-wipe-data` as a migration step.

## Validation and rollout

Follow the repo's tracer-bullet rule: first expose the composed SDK and verify
T3 detects it; stop for feedback before expanding into automatic AVD management.
Build only the Android package during that first slice. Do not build the whole
system unless explicitly requested.

- [ ] Confirm architecture and package versions, including the image revision.
- [ ] Verify `android`, `adb`, `emulator`, and `avdmanager` resolve to Nix packages.
- [ ] Verify the exact T3-required files under `ANDROID_HOME` exist and execute.
- [ ] Run `emulator -list-avds` and `avdmanager list avd`.
- [ ] Boot the disposable Android 36 ARM64 device and verify `adb devices` and
  `adb shell getprop sys.boot_completed` (use `-s SERIAL` when multiple devices exist).
- [ ] Restart T3 fully, refresh Device hub, and verify device listing, launch,
  display, and control. Test launching T3 from Finder as well as a shell; a shell
  environment alone does not prove the GUI process sees the new SDK.
- [ ] Once approved, apply using
  `sudo darwin-rebuild switch --flake .#Omars-MacBook-Pro`.
- [ ] Verify the original `medium_phone` and a second switch preserve device data.
- [ ] Keep iOS discovery troubleshooting separate; changing the Android SDK will
  not fix T3's misleading iOS runtime warning.

## Remove the manual installation after successful migration

Do not execute cleanup until the Nix tools and T3 work. Stop emulators and quit
T3 before moving files. Keep a rollback backup until a later successful restart.

The following are **bash/zsh** commands, not fish syntax:

```sh
android_backup="$HOME/android-manual-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$android_backup"

# Preserve writable state and keys privately; never commit this directory.
cp -pR "$HOME/.android" "$android_backup/android-user-state"

# Retire only the manual SDK and installer-managed launchers.
mv "$HOME/Library/Android/sdk" "$android_backup/sdk"
mv "$HOME/.local/bin/android" "$android_backup/android-launcher"
mv "$HOME/.android/bin/android-cli" "$android_backup/android-cli"
```

Inspect each path before moving it: these commands assume the manual paths still
exist and have not been replaced with Nix-managed links. If the future design
uses the old SDK location as a compatibility symlink, move the manual directory
before activating that link instead.

- [ ] Keep `~/.android/avd`, `adbkey`, and `adbkey.pub` in place. Do not delete
  `~/.android` wholesale or remove T3's `~/.t3` data.
- [ ] Inspect `~/.android/cli/bundles` after the Nix CLI has run. It may contain
  downloaded helper runtimes still used by the CLI. A Nix-installed launcher alone
  does not prove all CLI helpers are declarative: package/pin required helpers or
  document this remaining runtime-download dependency before claiming completion.
- [ ] Remove obsolete installer PATH entries, SDK overrides, and shell aliases
  only after inspection. Keep `~/.local/bin` on PATH for unrelated programs.
  No Android-specific entries were found in the inspected shell files, but check
  fish universal variables and any newly generated CLI config too.
- [ ] Open a new terminal and repeat the validation with the manual SDK absent.
  Use `type -a android adb emulator avdmanager` to detect shadowed commands.
- [ ] Once satisfied, delete only the dated backup directory created above using
  Finder. Until then, restore its moved files and the previous Nix generation to
  roll back. Never overwrite newer AVD data blindly with the backup.

## References

- [Nixpkgs Android documentation](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/android.section.md)
- [SDK composition implementation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/androidenv/compose-android-packages.nix)
- [Nixpkgs Android CLI package](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/an/android-cli/package.nix)
- [Google Android CLI commands](https://developer.android.com/agents/skills/devtools/android-cli/skill)

Check the repo's locked nixpkgs source when implementing; upstream `master` and
Google's live package catalog can differ from the pinned versions.
