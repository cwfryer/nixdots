# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    inputs.neovim-flake.nixosModules."x86_64-linux".hm
    inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  colorScheme = inputs.nix-colors.colorSchemes.oceanicnext;

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # inputs.neovim-nightly.overlay
      inputs.nur.overlay

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "casey";
    homeDirectory = "/home/casey";
  };

  # Add stuff for your user as you see fit:
  # NixOS Packages for user (search.nixos.org)
  home.packages = with pkgs; [
    obsidian
    zoom-us
    ripgrep
    fd
    variety
    android-studio
    zellij
  ];

  # Home-Manager programs for user (mipmip.github.io/home-manager-option-search)
  programs = {
    # neovim = {
    #   enable = true;
    # };
    neovim-ide = {
      # my personal neovim flake, from github:cwfryer/neovim-flake
      enable = true;
      settings = {
        vim = {
          viAlias = false;
          vimAlias = true;
          coding = {
            enable = true;
            snippets = {
              enable = true;
              useFriendlySnippets = true;
            };
            completion = {
              enable = true;
              useSuperTab = true;
              completeFromLSP = true;
              completeFromBuffer = true;
              completeFromPath = true;
              completeFromLuaSnip = true;
            };
            helpers = {
              autoPair = true;
              surround = true;
              comment = {
                enable = true;
                useTreeSitterContext = true;
              };
              betterAISelection = true;
            };
          };
          colorscheme = {
            set = "oceanicnext";
            transparent = true;
          };
          editor = {
            enable = true;
            enableTree = true;
            improveSearchReplace = true;
            enableTelescope = true;
            movement = {
              enableFlit = true;
              enableLeap = true;
            };
            visuals = {
              enableGitSigns = true;
              enableIlluminate = true;
              betterTODOComments = true;
            };
            improveDiagnostics = true;
            enableFloatingTerminal = true;
          };
          keys = {
            enable = true;
            whichKey.enable = true;
          };
          lsp = {
            enable = true;
            extras = {
              neoconf = true;
              neodev = true;
            };
            autoFormatting = true;
            languages = {
              lua = true;
              nix = true;
              rust = true;
              # Uncomment to enable
              # go = true;
              # pyton = true;
              # typescript = true;
            };
          };
          treesitter = {
            enable = true;
            textobjects = true;
          };
          ui = {
            enable = true;
            uiTweaks = {
              system = "noice.nvim";
              interfaces = true;
              icons = true;
              indents = true;
            };
            uiAdditions = {
              bufferline = true;
              lualine = {
                enable = true;
                improveContext = true;
              };
              indents = true;
              dashboard = "mini.starter";
            };
          };
          util = {
            enable = true;
            sessions = true;
          };
        };
      };
    };

    firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraPolicies = {
          CaptivePortal = false;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DisableFirefoxAccounts = false;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          OfferToSaveLoginsDefault = false;
          PasswordManagerEnabled = false;
          FirefoxHome = {
            Search = true;
            Pocket = false;
            Snippets = false;
            TopSites = false;
            Highlights = false;
          };
          UserMessaging = {
            ExtensionRecommendations = false;
            SkipOnboarding = true;
          };
        };
      };
      profiles = {
        default = {
          id = 0;
          isDefault = true;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            privacy-badger
            clearurls
            facebook-container
            multi-account-containers
            ninja-cookie
            # bypass-paywalls-clean
          ];
          search = {
            force = true;
            default = "DuckDuckGo";
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "{pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              "NixOS Wiki" = {
                urls = [
                  {
                    template = "https://nixos.wiki/index.php?search={searchTerms}";
                  }
                ];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@nw"];
              };
              "Google" = {
                urls = [
                  {
                    template = "https://www.google.com/search?q={searchTerms}";
                  }
                ];
                definedAliases = ["@g"];
              };
            };
          };
        };
      };
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true; # let home-manager manage itself

  # Home-Manager services for user
  services = {
    syncthing.enable = true;
    playerctld.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
