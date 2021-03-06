{ config, pkgs, ... }:
let
  mytexlive = pkgs.texlive.combine {
    inherit (pkgs.texlive)
    scheme-full
    collection-xetex;
  };
in {
  nixpkgs.config.allowUnfree = true;

  imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];
  
  boot.initrd.availableKernelModules = [ "ahci" "xhci_hcd" ];
  boot.initrd.kernelModules = [ "wl" ];
  
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/ba82dd25-a9e5-436f-ae76-4ee44d53b2c6";
      fsType = "ext4";
    };
    "/home" = {
      device = "/dev/disk/by-uuid/b27c07d0-aaf7-44a1-87e1-5a2cb30954ec";
      fsType = "ext4";
    };
  };
  swapDevices = [
    # TODO: set priority
    # { device = "/dev/disk/by-uuid/f0bd0438-3324-4295-9981-07015fa0af5e"; }
    { device = "/dev/disk/by-uuid/75822d9d-c5f0-495f-b089-f57d0de5246d"; }
  ];
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
    extraEntries = ''
      menuentry 'Gentoo' {
        configfile (hd1,1)/grub2/grub.cfg
      }
    '';
  };
  nix.maxJobs = 8;
  nix.buildCores = 8;
  
  networking = {
    hostName = "Larry";
  
    useDHCP = false;
    wicd.enable = true;
    wireless.enable = false;
  
    extraHosts = ''
      127.0.0.1 Larry Larry.local
    '';
  };
  
  services.xserver.synaptics = {
    enable = true;
    twoFingerScroll = true;
    vertEdgeScroll = true;
  };
  hardware.nvidiaOptimus.disable = true;

  users.extraUsers.rasen = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "users" "wheel" "networkmanager" "dialout" "plugdev" ];
    initialPassword = "HelloWorld";
  };
  nix.useChroot = true;
  services.openvpn.servers = {
    kaa.config = ''
      client
      dev tap
      port 22
      proto tcp
      tls-client
      persist-key
      persist-tun
      ns-cert-type server
      remote vpn.kaa.org.ua
      ca /root/.vpn/ca.crt
      key /root/.vpn/alexey.shmalko.key
      cert /root/.vpn/alexey.shmalko.crt
    '';
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
      workstation = true;
    };
  };
  systemd.services.avahi-daemon.wantedBy = [ "multi-user.target" ];
  systemd.services.avahi-daemon.after = [ "openvpn-kaa.target" ];
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  services.gitolite = {
    enable = true;
    adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJhMhxIwZJgIY6CNSNEH+BetF/WCUtDFY2KTIl8LcvXNHZTh4ZMc5shTOS/ROT4aH8Awbm0NjMdW33J5tFMN8T7q89YZS8hbBjLEh8J04Y+kndjnllDXU6NnIr/AenMPIZxJZtSvWYx+f3oO6thvkZYcyzxvA5Vi6V1cGx6ni0Kizq/WV/mE/P1nNbwuN3C4lCtiBC9duvoNhp65PctQNohnKQs0vpQcqVlfqBsjQ7hhj2Fjg+Ofmt5NkL+NhKQNqfkYN5QyIAulucjmFAieKR4qQBABopl2F6f8D9IjY8yH46OCrgss4WTf+wxW4EBw/QEfNoKWkgVoZtxXP5pqAz rasen@Larry";
  };
  services.dnsmasq = {
    enable = true;
  
    # These are used in addition to resolv.conf
    servers = [ "8.8.8.8" "8.8.4.4" ];
  
    extraConfig = ''
      listen-address=127.0.0.1
      cache-size=1000
  
      no-negcache
    '';
  };
  
  # Put the text in /etc/resolv.conf.head
  #
  # That will prepend dnsmasq server to /etc/resolv.conf (dhcpcd-specific)
  environment.etc."resolv.conf.head".text = ''
    nameserver 127.0.0.1
  '';
  services.xserver.enable = true;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  time.timeZone = "Europe/Kiev";
  services.xserver.displayManager.slim.enable = true;
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = [ pkgs.luaPackages.luafilesystem ];
  };
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.layout = "us,ru,ua";
  services.xserver.xkbOptions = "grp:caps_toggle,grp:menu_toggle,grp_led:caps";
  services.redshift = {
    enable = true;
    latitude = "50.4500";
    longitude = "30.5233";
  };
  environment.shellInit = ''
    export GTK_PATH=$GTK_PATH:${pkgs.oxygen_gtk}/lib/gtk-2.0
    export GTK2_RC_FILES=$GTK2_RC_FILES:${pkgs.oxygen_gtk}/share/themes/oxygen-gtk/gtk-2.0/gtkrc
  '';
  fonts = {
    enableCoreFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = false;
  
    fonts = with pkgs; [
      powerline-fonts
      inconsolata
      corefonts
      terminus_font
      dejavu_fonts
      source-code-pro
      ubuntu_font_family
      unifont
    ];
  };
  environment.pathsToLink = [ "/share" ];
  nixpkgs.config.firefox.jre = true;
  nixpkgs.config.packageOverrides = pkgs: rec {
    jrePlugin = pkgs.icedtea_web;
  };
  environment.sessionVariables.MT_TEXMFMAIN = "${mytexlive}/share/texmf/";
  programs.zsh.enable = true;
  
  users.defaultUserShell = "/run/current-system/sw/bin/zsh";
  users.extraGroups.plugdev = { };
  services.udev.packages = [ pkgs.openocd ];
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  environment.systemPackages = [
    pkgs.wmname
    pkgs.kbdd
    pkgs.xclip
    pkgs.scrot
    pkgs.xxkb
    pkgs.kde4.oxygen_icons
    pkgs.kde4.kwin_styles
    pkgs.oxygen-gtk2
    pkgs.oxygen-gtk3
    pkgs.gnome3.adwaita-icon-theme
    pkgs.kde4.okular
    pkgs.kde4.gwenview
    pkgs.kde4.kde_baseapps # <-- dolphin
    pkgs.kde4.kde_runtime
    pkgs.kde4.kfilemetadata
    pkgs.kde4.filelight
    pkgs.shared_mime_info
    pkgs.firefoxWrapper
    mytexlive
    pkgs.google-chrome
    pkgs.skype
    pkgs.libreoffice
    pkgs.qbittorrent
    pkgs.calibre
    pkgs.mnemosyne
    pkgs.deadbeef
    pkgs.wine
    pkgs.vlc
    pkgs.mplayer
    pkgs.smplayer
    pkgs.gparted
    pkgs.unetbootin
    pkgs.kvm
    pkgs.thunderbird
    pkgs.xscreensaver
    pkgs.xss-lock
    (pkgs.vim_configurable.override { python3 = true; })
    pkgs.emacs
    pkgs.ycmd
    pkgs.racerRust
    pkgs.ditaa
    pkgs.jre
    pkgs.rxvt_unicode
    pkgs.gitFull
    pkgs.gitg
    pkgs.tmux
    pkgs.ghc
    pkgs.haskellPackages.ghc-mod
    pkgs.stack
    pkgs.cabal-install
    pkgs.cabal2nix
    pkgs.gnumake
    pkgs.cmake
    pkgs.binutils
    pkgs.gcc
    pkgs.gcc-arm-embedded
    (pkgs.gdb.override { multitarget = true; })
    pkgs.minicom
    pkgs.openocd
    pkgs.expect
    pkgs.telnet
    pkgs.arduino
    pkgs.wget
    pkgs.htop
    pkgs.psmisc
    pkgs.mosh
    pkgs.zip
    pkgs.unzip
    pkgs.unrar
    pkgs.p7zip
    pkgs.irssi
    pkgs.man-pages
    pkgs.bind
    pkgs.file
    pkgs.which
    pkgs.whois
    pkgs.gnupg
    pkgs.utillinuxCurses
    
    pkgs.patchelf
    
    pkgs.nix-repl
    pkgs.nox
    pkgs.python
    pkgs.python3
    pkgs.steam
    pkgs.nethack
  ];

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";
}
