{
  services.casparcg-server.enable = true;
  services.casparcg-server.autoStart = true;
  fileSystems."/".device = "/dev/null";
  boot.loader.grub.enable = false;
  system.stateVersion = "25.11";
}
