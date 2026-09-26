{
  lib,
  stdenvNoCC,
  writeText,
  ripgrep,
  codex,
}:
let
  targets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-darwin = "x86_64-apple-darwin";
    x86_64-linux = "x86_64-unknown-linux-musl";
    aarch64-linux = "aarch64-unknown-linux-musl";
  };
  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "Codex is not packaged for ${stdenvNoCC.hostPlatform.system}");

  # codex >= 0.157 refuses to start its app-server daemon unless the running
  # executable sits inside a package root described by this manifest. Upstream
  # ships bare binaries under libexec, so the layout is rebuilt here instead.
  manifest = writeText "codex-package.json" (
    builtins.toJSON {
      layoutVersion = 1;
      inherit (codex) version;
      inherit target;
      variant = "codex";
      entrypoint = "bin/codex";
      resourcesDir = "codex-resources";
      pathDir = "codex-path";
    }
  );
in
stdenvNoCC.mkDerivation {
  pname = "codex-packaged";
  inherit (codex) version;

  dontUnpack = true;

  # Prebuilt, already-signed release binaries; copy them through untouched.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    root="$out/libexec/codex-package"
    mkdir -p "$root/bin" "$root/codex-path" "$out/bin"

    # The entrypoint has to be a real file. Codex canonicalises its own
    # executable before looking for codex-package.json, so a symlink pointing
    # back into the store would resolve outside the package root.
    install -m755 ${codex}/libexec/codex "$root/bin/codex"
    install -m755 ${codex}/libexec/codex-code-mode-host "$root/bin/codex-code-mode-host"
    install -m755 ${ripgrep}/bin/rg "$root/codex-path/rg"
    install -m644 ${manifest} "$root/codex-package.json"

    # Resolving these links lands inside the package root, which is allowed.
    ln -s ../libexec/codex-package/bin/codex "$out/bin/codex"
    ln -s ../libexec/codex-package/bin/codex-code-mode-host "$out/bin/codex-code-mode-host"

    cp -R ${codex}/share "$out/share"

    runHook postInstall
  '';

  meta = {
    description = "OpenAI Codex CLI, laid out as a self-contained package root";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames targets;
  };
}
