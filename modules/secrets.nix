{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.jn.secrets;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  names = lib.attrNames cfg.env;
  secretPath = name: "$HOME/${cfg.dir}/${name}";

  provision = pkgs.writeShellApplication {
    name = "jn-secrets-provision";
    text = ''
      dir="$HOME/${cfg.dir}"

      umask 077

      # Activation runs this, so every failure below warns and exits 0.
      errfile=""
      if ! mkdir -p "$dir" || ! chmod 700 "$dir" \
        || ! errfile="$(mktemp "$dir/.errors.XXXXXX")"; then
        echo "secrets: WARNING could not prepare $dir; leaving secrets alone." >&2
        exit 0
      fi
      trap 'rm -f -- "$errfile" || true' EXIT

      provision() {
        name="$1"
        ref="$2"
        tmp=""

        if ! value="$(${cfg.opCommand} read "$ref" 2>"$errfile")" || [ -z "$value" ]; then
          reason="$(head -n 1 "$errfile" || true)"
          echo "secrets: WARNING could not read $name''${reason:+ ($reason)}; keeping the existing value." >&2
          return 0
        fi

        if tmp="$(mktemp "$dir/.$name.XXXXXX")" \
          && printf '%s' "$value" > "$tmp" \
          && mv -f "$tmp" "$dir/$name"; then
          return 0
        fi

        rm -f -- "$tmp" || true
        echo "secrets: WARNING could not write $name; keeping the existing value." >&2
      }

      ${lib.concatMapStringsSep "\n" (
        name: "provision ${name} ${lib.escapeShellArg cfg.env.${name}}"
      ) names}
    '';
  };
in
{
  options.jn.secrets = {
    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Env var name to `op://` reference. Each value is fetched at activation
        into its own file under `dir` and exported by fish at shell start.
      '';
    };

    opCommand = lib.mkOption {
      type = lib.types.str;
      default = "/usr/bin/env -u OP_SERVICE_ACCOUNT_TOKEN ${
        if isDarwin then "/usr/local/bin/op" else "/run/wrappers/bin/op"
      }";
      description = ''
        Desktop `op` invocation for the user's own vaults. With
        `OP_SERVICE_ACCOUNT_TOKEN` exported, `op` would otherwise switch to the
        service account, which cannot read the Personal vault. Hosts have no
        reason to set it; the flake check overrides it with a stub `op` to
        exercise the provisioner.
      '';
    };

    dir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "Home-relative directory holding one file per registered name.";
    };

    provisioner = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Fetches every registered reference into `dir`.";
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.all (name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name != null) names;
        message = "jn.secrets.env names are interpolated into shell code and must be plain identifiers.";
      }
    ];

    jn.secrets = {
      env.OP_SERVICE_ACCOUNT_TOKEN = lib.mkDefault "op://Agents/Agents service account token/password";
      dir = ".config/jn/secrets";
      provisioner = provision;
    };

    home.activation.jnSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe provision} \
        || echo "secrets: WARNING provisioner failed; activation continues." >&2
    '';

    # Only a file with non-blank content is exported, so an unprovisioned name never shadows a tool's own auth.
    programs.fish.shellInit = lib.concatMapStringsSep "\n" (name: ''
      test -s "${secretPath name}"; and set -l v (string collect < "${secretPath name}"); and string match -qr '\S' -- "$v"; and set -gx ${name} $v
    '') names;

    # A function rather than an alias: fish appends $argv to an alias body, which breaks a loop.
    programs.fish.functions.jn-secrets-check = ''
      for name in ${lib.concatStringsSep " " names}
        if test -n "$$name"
          echo "present $name"
        else
          echo "missing $name"
        end
      end
    '';
  };
}
