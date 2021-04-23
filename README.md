Home Manager using Nix
======================

This project provides a basic system for managing a user environment
using the [Nix][] package manager together with the Nix libraries
found in [Nixpkgs][]. It allows declarative configuration of user
specific (non global) packages and dotfiles.

Before attempting to use Home Manager please read the warning below.

For a more systematic overview of Home Manager and its available
options, please see the [Home Manager manual][manual].

Words of warning
----------------

Unfortunately, it is quite possible to get difficult to understand
errors when working with Home Manager, such as infinite loops with no
clear source reference. You should therefore be comfortable using the
Nix language and the various tools in the Nix ecosystem. Reading
through the [Nix Pills][] document is a good way to familiarize
yourself with them.

If you are not very familiar with Nix but still want to use Home
Manager then you are strongly encouraged to start with a small and
very simple configuration and gradually make it more elaborate as you
learn.

In some cases Home Manager cannot detect whether it will overwrite a
previous manual configuration. For example, the Gnome Terminal module
will write to your dconf store and cannot tell whether a configuration
that it is about to be overwritten was from a previous Home Manager
generation or from manual configuration.

Home Manager targets [NixOS][] unstable and NixOS version 20.09 (the
current stable version), it may or may not work on other Linux
distributions and NixOS versions.

Also, the `home-manager` tool does not explicitly support rollbacks at
the moment so if your home directory gets messed up you'll have to fix
it yourself. See the [rollbacks](#rollbacks) section for instructions
on how to manually perform a rollback.

Now when your expectations have been built up and you are eager to try
all this out you can go ahead and read the rest of this text.

Contact
-------

You can chat with us on IRC in the channel [#home-manager][] on
[freenode][]. The [channel logs][] are hosted courtesy of
[samueldr][].

Installation
------------

Currently the easiest way to install Home Manager is as follows:

1.  Make sure you have a working Nix installation. Specifically, make
    sure that your user is able to build and install Nix packages. For
    example, you should be able to successfully run a command like
    `nix-instantiate '<nixpkgs>' -A hello` without having to switch to
    the root user. For a multi-user install of Nix this means that
    your user must be covered by the
    [`allowed-users`][nixAllowedUsers] Nix option. On NixOS you can
    control this option using the
    [`nix.allowedUsers`][nixosAllowedUsers] system option.

    Note that Nix 2.4 (`nixUnstable`) is not yet supported.

2.  Add the appropriate Home Manager channel. If you are following
    Nixpkgs master or an unstable channel you can run

    ```console
    $ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    $ nix-channel --update
    ```

    and if you follow a Nixpkgs version 20.09 channel you can run

    ```console
    $ nix-channel --add https://github.com/nix-community/home-manager/archive/release-20.09.tar.gz home-manager
    $ nix-channel --update
    ```

    On NixOS you may need to log out and back in for the channel to
    become available. On non-NixOS you may have to add

    ```shell
    export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
    ```

    to your shell (see [nix#2033](https://github.com/NixOS/nix/issues/2033)).

3.  Install Home Manager and create the first Home Manager generation:

    ```console
    $ nix-shell '<home-manager>' -A install
    ```

    Once finished, Home Manager should be active and available in your
    user environment.

3.  If you do not plan on having Home Manager manage your shell
    configuration then you must source the

    ```
    $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
    ```

    file in your shell configuration. Unfortunately, in this specific
    case we currently only support POSIX.2-like shells such as
    [Bash][] or [Z shell][].

    For example, if you use Bash then add

    ```bash
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    ```

    or this when managing home configuration together with system
    configuration

    ```bash
    . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
    ```

    to your `~/.profile` file.

If instead of using channels you want to run Home Manager from a Git
checkout of the repository then you can use the
`programs.home-manager.path` option to specify the absolute path to
the repository.

Usage
-----

Home Manager is typically managed through the `home-manager` tool.
This tool can, for example, apply configurations to your home
directory, list user packages installed by the tool, and list the
configuration generations.

As an example, let us expand the initial configuration file from the
installation above to install the htop and fortune packages, install
Emacs with a few extra packages enabled, install Firefox with
smooth scrolling enabled, and enable the user gpg-agent service.

To satisfy the above setup we should elaborate the
`~/.config/nixpkgs/home.nix` file as follows:

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.htop
    pkgs.fortune
  ];

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.magit
    ];
  };

  programs.firefox = {
    enable = true;
    profiles = {
      myprofile = {
        settings = {
          "general.smoothScroll" = false;
        };
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  programs.home-manager = {
    enable = true;
    path = "…";
  };
}
```

To activate this configuration you can then run

```console
$ home-manager switch
```

or if you are not feeling so lucky,

```console
$ home-manager build
```

which will create a `result` link to a directory containing an
activation script and the generated home directory files.

Documentation of available configuration options, including
descriptions and usage examples, is available in the [Home Manager
manual][configuration options] or offline by running

```console
$ man home-configuration.nix
```

Rollbacks
---------

While the `home-manager` tool does not explicitly support rollbacks at
the moment it is relatively easy to perform one manually. The steps to
do so are

1.  Run `home-manager generations` to determine which generation you
    wish to rollback to:

    ```console
    $ home-manager generations
    2018-01-04 11:56 : id 765 -> /nix/store/kahm1rxk77mnvd2l8pfvd4jkkffk5ijk-home-manager-generation
    2018-01-03 10:29 : id 764 -> /nix/store/2wsmsliqr5yynqkdyjzb1y57pr5q2lsj-home-manager-generation
    2018-01-01 12:21 : id 763 -> /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation
    2017-12-29 21:03 : id 762 -> /nix/store/6c0k1r03fxckql4vgqcn9ccb616ynb94-home-manager-generation
    2017-12-25 18:51 : id 761 -> /nix/store/czc5y6vi1rvnkfv83cs3rn84jarcgsgh-home-manager-generation
    …
    ```

2.  Copy the Nix store path of the generation you chose, e.g.,

        /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation

    for generation 763.

3.  Run the `activate` script inside the copied store path:

    ```console
    $ /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation/activate
    Starting home manager activation
    …
    ```

Keeping your ~ safe from harm
-----------------------------

To configure programs and services Home Manager must write various
things to your home directory. To prevent overwriting any existing
files when switching to a new generation, Home Manager will attempt to
detect collisions between existing files and generated files. If any
such collision is detected the activation will terminate before
changing anything on your computer.

For example, suppose you have a wonderful, painstakingly created
`~/.config/git/config` and add

```nix
{
  # …

  programs.git = {
    enable = true;
    userName = "Jane Doe";
    userEmail = "jane.doe@example.org";
  };

  # …
}
```

to your configuration. Attempting to switch to the generation will
then result in

```console
$ home-manager switch
…
Activating checkLinkTargets
Existing file '/home/jdoe/.gitconfig' is in the way
Please move the above files and try again
```

Graphical services
------------------

Home Manager includes a number of services intended to run in a
graphical session, for example `xscreensaver` and `dunst`.
Unfortunately, such services will not be started automatically unless
you let Home Manager start your X session. That is, you have something
like

```nix
{
  # …

  services.xserver.enable = true;

  # …
}
```

in your system configuration and

```nix
{
  # …

  xsession.enable = true;
  xsession.windowManager.command = "…";

  # …
}
```

in your Home Manager configuration.

Nix Flakes
----------

Home Manager includes a `flake.nix` file for compatibility with [Nix Flakes][]
for those that wish to use it as a module. A bare-minimum `flake.nix` would be
as follows:

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { home-manager, nixpkgs, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jdoe = import ./home.nix;
          }
        ];
      };
    };
  };
}
```

Note that the `home-manager` uses its own nixpkgs input, which is updated
periodically. See the wiki for more details.
The Home Manager library is exported by the flake under `lib.hm`.

When using flakes, switch to new configurations as you do for the
whole system (e. g. `nixos-rebuild switch --flake <path>`) instead of
using the `home-manager` command line tool.

Releases
--------

Home Manager is developed against `nixpkgs-unstable` branch, which
often causes it to contain tweaks for changes/packages not yet
released in stable NixOS. To avoid breaking users' configurations,
Home Manager is released in branches corresponding to NixOS releases
(e.g. `release-20.09`). These branches get fixes, but usually not new
modules. If you need a module to be backported, then feel free to open
an issue.

[Bash]: https://www.gnu.org/software/bash/
[Nix]: https://nixos.org/nix/
[NixOS]: https://nixos.org/
[Nixpkgs]: https://nixos.org/nixpkgs/
[nixAllowedUsers]: https://nixos.org/nix/manual/#conf-allowed-users
[nixosAllowedUsers]: https://nixos.org/nixos/manual/options.html#opt-nix.allowedUsers
[Z shell]: http://zsh.sourceforge.net/
[manual]: https://nix-community.github.io/home-manager/
[configuration options]: https://nix-community.github.io/home-manager/options.html
[#home-manager]: https://webchat.freenode.net/?url=irc%3A%2F%2Firc.freenode.net%2Fhome-manager
[freenode]: https://freenode.net/
[channel logs]: https://logs.nix.samueldr.com/home-manager/
[samueldr]: https://github.com/samueldr/
[Nix Pills]: https://nixos.org/nixos/nix-pills/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
