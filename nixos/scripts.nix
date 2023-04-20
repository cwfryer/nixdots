{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # following script from:
  # https://github.com/wiltaylor/dotfiles/blob/master/roles/core/scripts.nix
  # usage from:
  # https://github.com/jordanisaacs/dotfiles/blob/master/scripts/default.nix
  sysTools = with pkgs;
    writeScriptBin "sys" ''
      #!${runtimeShell}
      if [ -n "$INNIXSHELLHOME" ]; then
        echo "You are in a nix shell that redirected home!"
        echo "SYS will not work from here properly."
        exit 1
      fi

      case $1 in
        "clean")
          echo "Running garbage collection"
          nix store gc
          echo "Deduplication running... may take a while"
          nix store optimise
        ;;

        "update")
          echo "Updating nixos flake..."
          pushd ~/nixdots
          nix flake update
          popd
        ;;

        "update-index")
          echo "Updating index... may take a while"
          nix-index
        ;;

        "save")
          echo "Saving changes"
          pushd ~/nixdots
          git diff
          git add .
          git commit
          git pull --rebase
          git push
          popd
        ;;

        "find")
          if [ -z "$3" ]; then
              nix search nixpkgs $2
          elif [ $3 = "--dot" ]; then
            nix search github:cwfryer/nixdots $2
          else
            echo "Unknown option $3"
          fi
        ;;

        "find-doc")
          ${manix}/bin/manix $2
        ;;

        "find-cmd")
          nix-locate --whole-name --type x --type s --no-group --type x --type s --top-level --at-root "/bin/$2"
        ;;

        "apply")
          pushd ~/nixdots
          if [ -z "$2" ]; then
            sudo nixos-rebuild switch --flake '.#'
          elif [ $2 = "--boot" ]; then
            sudo nixos-rebuild boot --flake '.#'
          elif [ $2 = "--test" ]; then
            sudo nixos-rebuild test --flake '.#'
          elif [ $2 = "--check" ]; then
            nixos-rebuild dry-activate --flake '.#'
          else
            echo "Unknown option $2"
          fi
          popd
        ;;

        "apply-user")
          pushd ~/nixdots

          #--impure is required so package can reach out to /etc/hmsystemdata.json
          #nix build --impure .#homeManagerConfigurations.$USER.activationPackage
          #./result/activate
          home-manager switch --flake .#casey@nixos
          popd
        ;;

        "iso")
          echo "Building iso file $2"
          pushd ~/nixdots
          nix build ".#installMedia.$2.config.system.build.isoImage"

          if [ -z "$3" ]; then
            echo "ISO Image is located at ~/nixdots/result/iso/nixos.iso"
          elif [ $3 = "--burn" ]; then
            if [ -z "$4" ]; then
              echo "Expected path to a usb drive following --burn"
            else
              sudo dd if=./result/iso/nixos.iso of=$4 status=progress bs=1M
            fi
          else
            echo "Unexpected option $3. Expected --burn"
          fi
          popd
        ;;

        "installed")
          nix-store -qR /run/current-system | sed -n -e 's/\/nix\/store\/[0-9a-z]\{32\}-//p' | sort | uniq
        ;;

        "depends")
          nix-store -qR $(which $2)
        ;;

        "which")
          nix show-derivation $(which $2) | jq -r '.[].outputs.out.path'
        ;;

        "exec")
          shift 1
          cmd=$1
          pkgs=$(nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$cmd")
          count=$(echo -n "$pkgs" | grep -c "^")

          case $count in
            0)
              >&2 echo "$1: not found!"
              exit 2
            ;;

            1)
              nix-build --no-out-link -A $pkgs "<nixpkgs>"
              if [ "$?" -eq 0 ]; then
                nix-shell -p $pkgs --run "$(echo $@)"
                exit $?
              fi
            ;;

            *)
              PS3="Please select package to run command from:"
              select p in $pkgs
              do
                nix-build --no-out-link -A $p "<nixpkgs>"
                if [ "$?" -eq 0 ]; then
                  nix-shell -p $pkgs --run "$(echo $@)"
                  exit $?
                fi

                >&2 echo "Unable to run command"
                exit $?
              done
            ;;
          esac
        ;;

        *)
          echo "Usage:"
          echo "sys command"
          echo ""
          echo "Commands:"
          echo "clean - Garbage collect and hard link nix store"
          echo "apply - Applies current system configuration in dotfiles."
          echo "apply-user - Applies current home manager configuration in dotfiles."
          echo "update - Updates dotfiles flake."
          echo "index - Updates index of nix used for exec (nix-index)"
          echo "find [--overlay] - Find a nix package (overlay for custom packages)"
          echo "find-doc - Finds documentation on a config item"
          echo "find-cmd - Finds the package a command is in"
          echo "installed - Lists all installed packages."
          echo "which - Prints the closure of target file"
          echo "exec - executes a command"
        ;;
      esac
    '';
in {
  nixpkgs.overlays = [
    (final: prev: {
      scripts.sysTools = sysTools;
    })
  ];
}
