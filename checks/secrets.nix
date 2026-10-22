{
  self,
  nixpkgs,
  user,
  system,
}:
let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = nixpkgs.lib;

  host =
    {
      aarch64-darwin = self.darwinConfigurations."Omars-MacBook-Pro";
      x86_64-linux = self.nixosConfigurations.nixos-jackcres;
    }
    .${system};

  homeOf = evaluated: evaluated.config.home-manager.users.${user};

  real = homeOf host;

  # Stand-in for `op`: prints a value derived from the reference, or fails on demand.
  # STUB_BLANK makes a read succeed with only whitespace.
  # STUB_LOCK names a directory to make read-only mid-read, to break the write.
  opStub = pkgs.writeShellScript "op-stub" ''
    [ "$1" = read ] || exit 64
    if [ -n "''${STUB_FAIL:-}" ]; then
      echo "LEAKED-STDOUT"
      printf 'stub: [ERROR] boom\nsecond line\n' >&2
      exit 1
    fi
    if [ -n "''${STUB_BLANK:-}" ]; then
      printf ' \n\t\n'
      exit 0
    fi
    [ -z "''${STUB_LOCK:-}" ] || chmod 500 "$STUB_LOCK"
    printf 'value-for-%s\n' "$2"
  '';

  token = "dummy-token";

  # Registered test names: files that hold nothing usable, one with no file at all,
  # and one that is provisioned but opts out of the export.
  unusable = {
    JN_CHECK_EMPTY = "";
    JN_CHECK_BLANK = "\n";
    JN_CHECK_SPACES = "  \n";
  };

  # The variant's home, so fish reads the files it would read for real, from `files`.
  fishHome = pkgs.runCommand "secrets-fish-home" { } ''
    dir="$out/${real.jn.secrets.dir}"
    mkdir -p "$dir"
    printf '%s\n' '${token}' > "$dir/OP_SERVICE_ACCOUNT_TOKEN"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: content: "printf '%s' ${lib.escapeShellArg content} > \"$dir/${name}\""
      ) unusable
    )}
    printf '%s\n' hidden-value > "$dir/JN_CHECK_HIDDEN"
  '';

  variant = homeOf (host.extendModules {
    modules = [
      {
        home-manager.users.${user} = {
          home.homeDirectory = lib.mkForce "${fishHome}";

          jn.secrets = {
            opCommand = "${opStub}";
            entries = lib.mapAttrs (name: _: "op://Agents/check/${name}") unusable // {
              JN_CHECK_MISSING = "op://Agents/check/missing";
              JN_CHECK_HIDDEN = {
                reference = "op://Agents/check/hidden";
                export = false;
              };
            };
          };
        };
      }
    ];
  });

  activation = real.home.activation;
  sortsCleanly = dag: (real.lib.dag.topoSort dag) ? result;

  # Siblings sort in an arbitrary but stable order, so a plain position check
  # passes by luck. Ordering is enforced exactly when asking jnSecrets to run
  # after the consumer makes the graph cyclic.
  forcedBefore =
    consumer:
    sortsCleanly activation
    && !sortsCleanly (
      activation
      // {
        jnSecrets = activation.jnSecrets // {
          after = activation.jnSecrets.after ++ [ consumer ];
        };
      }
    );

  # Consumers of the registry's files. The upstream seed entry exists only on darwin.
  orderedAfterSecrets =
    lib.optional (pkgs.stdenv.hostPlatform.isDarwin && activation ? cliproxyapi) "cliproxyapi"
    ++ [ "cliproxyapiRouteClients" ];

  callsOp = text: lib.hasInfix real.jn.secrets.opCommand text || lib.hasInfix "op read" text;
  offenders =
    lib.mapAttrsToList (name: _: "home.activation.${name}") (
      lib.filterAttrs (name: entry: name != "jnSecrets" && callsOp entry.data) activation
    )
    ++ lib.mapAttrsToList (name: _: "programs.fish.shellAliases.${name}") (
      lib.filterAttrs (_: callsOp) real.programs.fish.shellAliases
    );

  secrets = variant.jn.secrets;
  names = lib.attrNames secrets.entries;

  configFish = variant.xdg.configFile."fish/config.fish".source;
  checkFunction = variant.xdg.configFile."fish/functions/jn-secrets-check.fish".source;

  probe = pkgs.writeText "secrets-probe.fish" ''
    function fail
      echo "secrets check: $argv" >&2
      exit 1
    end

    source ${configFish}

    test "$OP_SERVICE_ACCOUNT_TOKEN" = ${token}
    or fail "OP_SERVICE_ACCOUNT_TOKEN was not read from its secret file"
    printenv OP_SERVICE_ACCOUNT_TOKEN >/dev/null
    or fail "OP_SERVICE_ACCOUNT_TOKEN was set but not exported"

    for name in ${lib.concatStringsSep " " (lib.attrNames unusable)} JN_CHECK_MISSING
      set -q $name
      and fail "$name was exported without usable content"
    end

    set -q JN_CHECK_HIDDEN
    and fail "JN_CHECK_HIDDEN was exported despite export = false"

    source ${checkFunction}
    set -l report (jn-secrets-check)

    for line in "present OP_SERVICE_ACCOUNT_TOKEN" "missing JN_CHECK_EMPTY" "missing JN_CHECK_MISSING" "provisioned OP_SERVICE_ACCOUNT_TOKEN" "provisioned JN_CHECK_HIDDEN" "unprovisioned JN_CHECK_EMPTY" "unprovisioned JN_CHECK_BLANK" "unprovisioned JN_CHECK_SPACES" "unprovisioned JN_CHECK_MISSING"
      contains -- $line $report
      or fail "jn-secrets-check did not report: $line"
    end

    for name in ${lib.concatStringsSep " " names}
      test (count (string match -r -- "^(?:un)?provisioned $name\$" $report)) -eq 1
      or fail "jn-secrets-check did not report $name exactly once as provisioned or not"
    end

    string match -q '*hidden-value*' -- $report
    and fail "jn-secrets-check printed a value"

    exit 0
  '';
in
assert lib.assertMsg (lib.all (entry: lib.hasPrefix "op://Agents/" entry.reference) (
  lib.attrValues secrets.entries
)) "every jn.secrets.entries reference must live in the Agents vault";
assert lib.assertMsg (lib.hasPrefix "/usr/bin/env -u OP_SERVICE_ACCOUNT_TOKEN " real.jn.secrets.opCommand)
  "jn.secrets.opCommand must run op without the service account token";
assert lib.assertMsg (sortsCleanly activation) "home.activation has an ordering cycle";
assert lib.all (
  consumer:
  lib.assertMsg (forcedBefore consumer) "home.activation.jnSecrets must run before home.activation.${consumer}"
) orderedAfterSecrets;
assert lib.assertMsg (offenders == [ ])
  "only the provisioner may call op, but these call it too: ${lib.concatStringsSep ", " offenders}";
pkgs.runCommand "jn-secrets-check-${system}"
  {
    nativeBuildInputs = [ variant.programs.fish.package ];
  }
  ''
    fail() {
      echo "secrets check: $*" >&2
      exit 1
    }

    mode() { stat -c %a "$1"; }

    # The export is read from the generated config.fish, as a login shell would.
    export HOME="$TMPDIR/fish-home"
    mkdir -p "$HOME"
    fish --no-config ${probe}

    provisioner=${lib.getExe secrets.provisioner}
    export HOME="$TMPDIR/prov-home"
    dir="$HOME/${secrets.dir}"
    mkdir -p "$HOME"

    snapshot() {
      (cd "$dir" && find . -mindepth 1 -exec stat -c '%a %n' {} + | sort; cat ./* 2>/dev/null) || true
    }

    "$provisioner" || fail "provisioner exited nonzero on a successful read"
    [ "$(mode "$dir")" = 700 ] || fail "secrets dir is not 0700"
    ${lib.concatMapStringsSep "\n" (name: ''
      [ "$(mode "$dir/${name}")" = 600 ] || fail "${name} is not 0600"
      [ "$(cat "$dir/${name}")" = ${lib.escapeShellArg "value-for-${secrets.entries.${name}.reference}"} ] \
        || fail "${name} holds the wrong value"
    '') names}
    [ "$(ls -A "$dir" | wc -l)" -eq ${toString (lib.length names)} ] \
      || fail "secrets dir holds files besides the registered names"
    first="$(snapshot)"

    STUB_FAIL=1 "$provisioner" 2> "$TMPDIR/warnings" \
      || fail "provisioner exited nonzero on a failed read"
    grep -q 'could not read OP_SERVICE_ACCOUNT_TOKEN (stub: \[ERROR\] boom)' "$TMPDIR/warnings" \
      || fail "failed read did not warn with op's first stderr line"
    ! grep -q 'LEAKED-STDOUT\|second line' "$TMPDIR/warnings" \
      || fail "warning included more than op's first stderr line"
    [ "$(snapshot)" = "$first" ] || fail "failed read changed the secrets dir"

    STUB_BLANK=1 "$provisioner" 2> "$TMPDIR/warnings" \
      || fail "provisioner exited nonzero on a blank read"
    grep -q 'could not read' "$TMPDIR/warnings" || fail "blank read did not warn"
    [ "$(snapshot)" = "$first" ] || fail "blank read changed the secrets dir"

    "$provisioner" || fail "provisioner exited nonzero on a rerun"
    [ "$(snapshot)" = "$first" ] || fail "rerun did not converge"

    STUB_LOCK="$dir" "$provisioner" 2> "$TMPDIR/warnings" \
      || fail "provisioner exited nonzero when the write failed"
    chmod 700 "$dir"
    if [ "$(id -u)" != 0 ]; then
      grep -q 'could not write' "$TMPDIR/warnings" || fail "failed write did not warn"
    fi
    export HOME="$TMPDIR/blocked-home"
    mkdir -p "$HOME"
    touch "$HOME/.config"
    "$provisioner" 2> "$TMPDIR/warnings" || fail "provisioner exited nonzero when the dir was unusable"
    grep -q 'could not prepare' "$TMPDIR/warnings" || fail "unusable dir did not warn"

    touch $out
  ''
