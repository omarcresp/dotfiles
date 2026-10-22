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

  # Reads whose callers must strip the service account token. Each exists only where its module sets it.
  opCallers = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    [
      "services"
      "cliproxyapi"
      "secretKeyCommand"
    ]
    [
      "services"
      "cliproxyapi"
      "apiKeyCommand"
    ]
    [
      "programs"
      "fish"
      "shellAliases"
      "jn-cpa-key"
    ]
  ];
  presentCallers = lib.filter (path: lib.hasAttrByPath path real) opCallers;

  # Stand-in for `op`: prints a value derived from the reference, or fails on demand.
  # STUB_LOCK names a directory to make read-only mid-read, to break the write.
  opStub = pkgs.writeShellScript "op-stub" ''
    [ "$1" = read ] || exit 64
    if [ -n "''${STUB_FAIL:-}" ]; then
      echo "LEAKED-STDOUT"
      printf 'stub: [ERROR] boom\nsecond line\n' >&2
      exit 1
    fi
    [ -z "''${STUB_LOCK:-}" ] || chmod 500 "$STUB_LOCK"
    printf 'value-for-%s\n' "$2"
  '';

  # Registered test names: files that hold nothing usable, and one with no file at all.
  unusable = {
    JN_CHECK_EMPTY = "";
    JN_CHECK_BLANK = "\n";
    JN_CHECK_SPACES = "  \n";
  };

  variant = homeOf (host.extendModules {
    modules = [
      {
        home-manager.users.${user}.jn.secrets = {
          opCommand = "${opStub}";
          env = lib.mapAttrs (name: _: "op://Agents/check/${name}") unusable // {
            JN_CHECK_MISSING = "op://Agents/check/missing";
          };
        };
      }
    ];
  });

  secrets = variant.jn.secrets;
  names = lib.attrNames secrets.env;
  token = "dummy-token";

  configFish = variant.xdg.configFile."fish/config.fish".source;

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

    exit 0
  '';
in
assert lib.assertMsg (lib.all (ref: lib.hasPrefix "op://Agents/" ref) (
  lib.attrValues secrets.env
)) "every jn.secrets.env reference must live in the Agents vault";
assert lib.assertMsg (lib.hasPrefix "/usr/bin/env -u OP_SERVICE_ACCOUNT_TOKEN " real.jn.secrets.opCommand)
  "jn.secrets.opCommand must run op without the service account token";
assert lib.assertMsg (lib.all (
  path: lib.hasPrefix real.jn.secrets.opCommand (lib.getAttrFromPath path real)
) presentCallers) "every op caller must go through jn.secrets.opCommand";
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
    mkdir -p "$HOME/${secrets.dir}"
    printf '%s\n' '${token}' > "$HOME/${secrets.dir}/OP_SERVICE_ACCOUNT_TOKEN"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: content: "printf '%s' ${lib.escapeShellArg content} > \"$HOME/${secrets.dir}/${name}\""
      ) unusable
    )}
    fish --no-config ${probe}

    provisioner=${lib.getExe secrets.provisioner}
    export HOME="$TMPDIR/prov-home"
    dir="$HOME/${secrets.dir}"
    mkdir -p "$HOME"

    snapshot() {
      (cd "$dir" && find . -mindepth 1 -exec stat -c '%a %n' {} + | sort; cat ./* 2>/dev/null) || true
    }

    # (a) a successful read writes 0600 files in a 0700 directory, and nothing else.
    "$provisioner" || fail "provisioner exited nonzero on a successful read"
    [ "$(mode "$dir")" = 700 ] || fail "secrets dir is not 0700"
    ${lib.concatMapStringsSep "\n" (name: ''
      [ "$(mode "$dir/${name}")" = 600 ] || fail "${name} is not 0600"
      [ "$(cat "$dir/${name}")" = ${lib.escapeShellArg "value-for-${secrets.env.${name}}"} ] \
        || fail "${name} holds the wrong value"
    '') names}
    [ "$(ls -A "$dir" | wc -l)" -eq ${toString (lib.length names)} ] \
      || fail "secrets dir holds files besides the registered names"
    first="$(snapshot)"

    # (b) a failing read exits 0, warns without leaking stdout, and keeps the existing files.
    STUB_FAIL=1 "$provisioner" 2> "$TMPDIR/warnings" \
      || fail "provisioner exited nonzero on a failed read"
    grep -q 'could not read OP_SERVICE_ACCOUNT_TOKEN (stub: \[ERROR\] boom)' "$TMPDIR/warnings" \
      || fail "failed read did not warn with op's first stderr line"
    ! grep -q 'LEAKED-STDOUT\|second line' "$TMPDIR/warnings" \
      || fail "warning included more than op's first stderr line"
    [ "$(snapshot)" = "$first" ] || fail "failed read changed the secrets dir"

    # (c) a second successful run converges to the same content, modes and file set.
    "$provisioner" || fail "provisioner exited nonzero on a rerun"
    [ "$(snapshot)" = "$first" ] || fail "rerun did not converge"

    # (d) a write that fails after the read still exits 0, and so does an unusable directory.
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
