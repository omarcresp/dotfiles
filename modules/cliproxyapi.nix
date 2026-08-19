{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  port = 8317;
  baseUrl = "http://127.0.0.1:${toString port}";
  opRead = ref: "/usr/local/bin/op read op://Personal/cliproxyapi/${ref}";

  # Both client configs are rewritten by their own tools, so patch only the keys
  # we own and leave the rest alone.
  routeClients = pkgs.writeShellApplication {
    name = "cliproxyapi-route-clients";
    runtimeInputs = [
      pkgs.jq
      pkgs.yq-go
    ];
    text = ''
      claude_settings="${config.home.homeDirectory}/.claude/settings.json"
      codex_config="${config.home.homeDirectory}/.codex/config.toml"

      token="$(${opRead "proxy-key"} 2>/dev/null || true)"
      if [ -z "$token" ]; then
        echo "cliproxyapi: WARNING could not read the proxy key; leaving client configs alone." >&2
        exit 0
      fi
      export token

      umask 077

      # ANTHROPIC_BASE_URL takes no /v1, unlike the Codex provider below.
      if [ -e "$claude_settings" ]; then
        jq --arg base "${baseUrl}" --arg token "$token" '
          .env = ((.env // {}) + {
            ANTHROPIC_BASE_URL: $base,
            ANTHROPIC_AUTH_TOKEN: $token,
            ANTHROPIC_DEFAULT_OPUS_MODEL: "claude-opus-5",
            ANTHROPIC_DEFAULT_SONNET_MODEL: "claude-sonnet-5",
            ANTHROPIC_DEFAULT_HAIKU_MODEL: "claude-haiku-4-5-20251001"
          })
        ' "$claude_settings" > "$claude_settings.tmp"
        chmod 600 "$claude_settings.tmp"
        mv "$claude_settings.tmp" "$claude_settings"
        echo "cliproxyapi: routed Claude Code through ${baseUrl}"
      else
        echo "cliproxyapi: WARNING $claude_settings not found; skipping Claude Code." >&2
      fi

      # model is left alone: Codex keeps its own GPT model through the proxy.
      if [ -e "$codex_config" ]; then
        yq -p toml -o toml '
          .model_provider = "cliproxyapi"
          | .model_providers.cliproxyapi.name = "OpenAI"
          | .model_providers.cliproxyapi.base_url = "${baseUrl}/v1"
          | .model_providers.cliproxyapi.wire_api = "responses"
          | .model_providers.cliproxyapi.requires_openai_auth = true
          | .model_providers.cliproxyapi.supports_websockets = true
          | .model_providers.cliproxyapi.experimental_bearer_token = strenv(token)
        ' "$codex_config" > "$codex_config.tmp"
        chmod 600 "$codex_config.tmp"
        mv "$codex_config.tmp" "$codex_config"
        echo "cliproxyapi: routed Codex through ${baseUrl}/v1"
      else
        echo "cliproxyapi: WARNING $codex_config not found; skipping Codex." >&2
      fi
    '';
  };
in
{
  home.activation.cliproxyapiRouteClients = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe routeClients}
  '';

  services.cliproxyapi = {
    enable = true;

    settings = {
      # Loopback only; the tailnet gets it through `tailscale serve`.
      host = "127.0.0.1";
      inherit port;
      debug = false;

      remote-management = {
        allow-remote = true;
        disable-control-panel = false;
        disable-auto-update-panel = true;
      };
    };

    # Read at activation so neither key reaches the Nix store.
    secretKeyCommand = opRead "secret-key";
    apiKeyCommand = opRead "proxy-key";

    tailscaleServePort = port;
  };

  imports = [ inputs.cliproxyapi.homeModules.default ];
}
