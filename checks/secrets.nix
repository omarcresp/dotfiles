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

  # Test-only names: one registered with an empty file, one with no file at all.
  probed = homeOf (host.extendModules {
    modules = [
      {
        home-manager.users.${user}.jn.secrets.env = {
          JN_CHECK_EMPTY = "op://Agents/check/empty";
          JN_CHECK_MISSING = "op://Agents/check/missing";
        };
      }
    ];
  });

  secrets = probed.jn.secrets;
  token = "dummy-token";

  shellInit = pkgs.writeText "fish-shell-init" probed.programs.fish.shellInit;
in
assert lib.assertMsg (lib.all (ref: lib.hasPrefix "op://Agents/" ref) (
  lib.attrValues secrets.env
)) "every jn.secrets.env reference must live in the Agents vault";
assert lib.assertMsg (lib.hasInfix "env -u OP_SERVICE_ACCOUNT_TOKEN" secrets.opCommand)
  "jn.secrets.opCommand must run op without the service account token";
pkgs.runCommand "jn-secrets-check-${system}"
  {
    nativeBuildInputs = [ probed.programs.fish.package ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/${secrets.dir}"
    printf '%s\n' '${token}' > "$HOME/${secrets.dir}/OP_SERVICE_ACCOUNT_TOKEN"
    : > "$HOME/${secrets.dir}/JN_CHECK_EMPTY"

    # The shell init also sources host files that do not exist in the sandbox.
    status=0
    fish --no-config -c '
      source ${shellInit}
      test "$OP_SERVICE_ACCOUNT_TOKEN" = ${token}; or exit 10
      printenv OP_SERVICE_ACCOUNT_TOKEN >/dev/null; or exit 11
      set -q JN_CHECK_EMPTY; and exit 12
      set -q JN_CHECK_MISSING; and exit 13
      exit 0
    ' || status=$?
    [ "$status" -eq 0 ] || { echo "fish shell init exported the wrong env (exit $status)" >&2; exit 1; }

    touch $out
  ''
