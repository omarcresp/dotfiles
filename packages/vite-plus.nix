{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.2.6";
  platformSources = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-sBrKIV3ZYLu+t3R6OleYcyzrbISEYdLkk37oIhiNfMQ=";
    };
    x86_64-linux = {
      suffix = "linux-x64-gnu";
      hash = "sha256-/OUQHHKeNWNa9BrEjPeiIJVcekF7HsKfij3PGGMH8KQ=";
    };
  };
  platform =
    platformSources.${stdenvNoCC.hostPlatform.system}
      or (throw "Vite+ is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "vite-plus";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${platform.suffix}/-/vite-plus-cli-${platform.suffix}-${version}.tgz";
    inherit (platform) hash;
  };

  sourceRoot = "package";

  installPhase = ''
    runHook preInstall

    install -Dm755 vp "$out/bin/vp"

    runHook postInstall
  '';

  meta = {
    description = "Unified toolchain for web development";
    homepage = "https://viteplus.dev";
    license = lib.licenses.mit;
    mainProgram = "vp";
    platforms = builtins.attrNames platformSources;
  };
}
