{ pkgs, ... }: let
  configFile = pkgs.writeTextFile {
    name = "config.kdb";
    text = ''
      (defcfg
        linux-continue-if-no-devs-found yes)

      (defsrc esc ret caps lctl ;)

      (deflayermap (base-layer)
        esc XX
        ret XX
        ;; bspc XX

        ;; [ bspc
        caps (tap-hold 50 120 esc lctl)
        lctl caps
        ;; f (tap-hold 200 250 f lalt)
        ;; j (tap-hold 200 250 j lalt)
        ; S-Period
        ;; ' (tap-hold 100 150 ret lctl)
        ;; IntlBackslash lsft
        ;; lalt @low
        ;; ralt @raise
      )
    '';

    checkPhase = ''
      ${pkgs.lib.getExe pkgs.kanata} --cfg "$target" --check --debug
    '';
  };
in {
  environment.systemPackages = [ pkgs.kanata ];

  launchd.daemons.kanata = {
    command = "${pkgs.lib.getExe pkgs.kanata} --cfg ${configFile}";
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = true;
    serviceConfig.StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
  };
}
