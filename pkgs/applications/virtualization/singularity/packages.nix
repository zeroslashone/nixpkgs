{
  callPackage,
  fetchFromGitHub,
  nixos,
  conmon,
}:
let
  apptainer =
    callPackage
      (import ./generic.nix rec {
        pname = "apptainer";
        version = "1.3.3";
        projectName = "apptainer";

        src = fetchFromGitHub {
          owner = "apptainer";
          repo = "apptainer";
          rev = "refs/tags/v${version}";
          hash = "sha256-xQZCQa9z1aJ2tVtxMlwcNhlm0EV/nn8OnbfaVZRm4JI=";
        };

        # Update by running
        # nix-prefetch -E "{ sha256 }: ((import ./. { }).apptainer.override { vendorHash = sha256; }).goModules"
        # at the root directory of the Nixpkgs repository
        vendorHash = "sha256-W853++SSvkAYYUczbl8vnoBQZnimUdsAEXp4MCkLPBU=";

        extraDescription = " (previously known as Singularity)";
        extraMeta.homepage = "https://apptainer.org";
      })
      {
        # Apptainer doesn't depend on conmon
        conmon = null;

        # Apptainer builders require explicit --with-suid / --without-suid flag
        # when building on a system with disabled unprivileged namespace.
        # See https://github.com/NixOS/nixpkgs/pull/215690#issuecomment-1426954601
        defaultToSuid = null;

        sourceFilesWithDefaultPaths = {
          "cmd/internal/cli/actions.go" = [ "/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin" ];
          "e2e/env/env.go" = [ "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ];
          "internal/pkg/util/env/env.go" = [ "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ];
        };
      };

  singularity =
    callPackage
      (import ./generic.nix rec {
        pname = "singularity-ce";
        version = "4.2.0";
        projectName = "singularity";

        src = fetchFromGitHub {
          owner = "sylabs";
          repo = "singularity";
          rev = "refs/tags/v${version}";
          hash = "sha256-CxHbUke0Y9BDnyqTRZZqNtU006XGxFj3gond1BaYZO0=";
        };

        # Update by running
        # nix-prefetch -E "{ sha256 }: ((import ./. { }).singularity.override { vendorHash = sha256; }).goModules"
        # at the root directory of the Nixpkgs repository
        vendorHash = "sha256-R4hMg5TX5YXtnBopl7CYYCwA540BAx98/aaNfLpExV4=";

        # Do not build conmon and squashfuse from the Git submodule sources,
        # Use Nixpkgs provided version
        extraConfigureFlags = [
          "--without-conmon"
          "--without-squashfuse"
        ];

        extraDescription = " (Sylabs Inc's fork of Singularity, a.k.a. SingularityCE)";
        extraMeta.homepage = "https://sylabs.io/";
      })
      {
        # Sylabs SingularityCE builders defaults to set the SUID flag
        # on UNIX-like platforms,
        # and only have --without-suid but not --with-suid.
        defaultToSuid = true;

        sourceFilesWithDefaultPaths = {
          "cmd/internal/cli/actions.go" = [ "/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin" ];
          "e2e/env/env.go" = [ "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ];
          "internal/pkg/util/env/clean.go" = [
            "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
      };

  genOverridenNixos =
    package: packageName:
    (nixos {
      programs.singularity = {
        enable = true;
        inherit package;
      };
    }).config.programs.singularity.packageOverriden.overrideAttrs
      (oldAttrs: {
        meta = oldAttrs.meta // {
          description = "";
          longDescription = ''
            This package produces identical store derivations to `pkgs.${packageName}`
            overriden and installed by the NixOS module `programs.singularity`
            with default configuration.

            This is for binary substitutes only. Use pkgs.${packageName} instead.
          '';
        };
      });
in
{
  inherit apptainer singularity;

  apptainer-overriden-nixos = genOverridenNixos apptainer "apptainer";
  singularity-overriden-nixos = genOverridenNixos singularity "singularity";
}
