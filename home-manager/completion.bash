#!/bin/env bash

##################################################

# « home-manager » command-line completion
#
# © 2019 "Sam Boosalis" <samboosalis@gmail.com>
#
# MIT License
#

##################################################
# Contributing:

# Compatibility — Bash 3.
#
# OSX won't update Bash 3 (last updated circa 2009) to Bash 4,
# and we'd like this completion script to work on both Linux and Mac.
#
# For example, OSX Yosemite (released circa 2014) ships with Bash 3:
#
#  $ echo $BASH_VERSION
#  3.2
#
# While Ubuntu LTS 14.04 (a.k.a. Trusty, also released circa 2016)
# ships with the latest version, Bash 4 (updated circa 2016):
#
#  $ echo $BASH_VERSION
#  4.3
#

# Testing
#
# (1) Invoke « shellcheck »
#
#     * source: « https://github.com/koalaman/shellcheck »
#     * run:    « shellcheck ./share/bash-completion/completions/home-manager »
#
# (2) Interpret via Bash 3
#
#     * run:    « bash --noprofile --norc ./share/bash-completion/completions/home-manager »
#

##################################################
# Examples:

# $ home-manager <TAB>
#
# -A
# -I
# -f
# --file
# -h
# --help
# -n
# --dry-run
# -v
# --verbose
# build
# edit
# expire-generations
# generations
# help
# news
# option
# packages
# remove-generations
# switch
# uninstall

# $ home-manager e<TAB>
#
# edit
# expire-generations

# $ home-manager remove-generations 20<TAB>
#
# 200
# 201
# 202
# 203

##################################################
# Notes:

# « home-manager » Subcommands:
#
#   help
#   edit
#   option
#   build
#   switch
#   generations
#   remove-generations
#   expire-generations
#   packages
#   news
#   uninstall

# « home-manager » Options:
#
#   -b EXT
#   -f FILE
#   --file FILE
#   -A ATTRIBUTE
#   -I PATH
#   -v
#   --verbose
#   -n
#   --dry-run
#   -h
#   --help

# $ home-manager
#
# Usage: /home/sboo/.nix-profile/bin/home-manager [OPTION] COMMAND
#
# Options
#
#   -f FILE      The home configuration file.
#                Default is '~/.config/nixpkgs/home.nix'.
#   -A ATTRIBUTE Optional attribute that selects a configuration
#                expression in the configuration file.
#   -I PATH      Add a path to the Nix expression search path.
#   -b EXT       Move existing files to new path rather than fail.
#   -v           Verbose output
#   -n           Do a dry run, only prints what actions would be taken
#   -h           Print this help
#
# Commands
#
#   help         Print this help
#
#   edit         Open the home configuration in $EDITOR
#
#   option OPTION.NAME
#                Inspect configuration option named OPTION.NAME.
#
#   build        Build configuration into result directory
#
#   switch       Build and activate configuration
#
#   generations  List all home environment generations
#
#   remove-generations ID...
#       Remove indicated generations. Use 'generations' command to
#       find suitable generation numbers.
#
#   expire-generations TIMESTAMP
#       Remove generations older than TIMESTAMP where TIMESTAMP is
#       interpreted as in the -d argument of the date tool. For
#       example "-30 days" or "2018-01-01".
#
#   packages     List all packages installed in home-manager-path
#
#   news         Show news entries in a pager
#
#   uninstall    Remove Home Manager
#
##################################################
# Dependencies:

command -v home-manager >/dev/null
command -v grep         >/dev/null
command -v sed          >/dev/null

##################################################
# Code:

_home-manager_list-generation-identifiers ()

{

    home-manager generations  |  sed -n -e 's/^................ : id \([[:alnum:]]\+\) -> .*/\1/p'

}

# NOTES
#
# (1) the « sed -n -e 's/.../.../p' » invocation:
#
#    * the « -e '...' » option takes a Sed Script.
#    * the « -n » option only prints when « .../p » would print.
#    * the « s/xxx/yyy/ » Sed Script substitutes « yyy » whenever « xxx » is matched.
#
# (2) the « '^................ : id \([[:alnum:]]\+\) -> .*' » regular expression:
#
#    * matches « 199 », for example, in the line « 2019-03-13 15:26 : id 199 -> /nix/store/mv619y9pzgsx3kndq0q7fjfvbqqdy5k8-home-manager-generation »
#
#

#------------------------------------------------#

# shellcheck disable=SC2120
_home-manager_list-nix-attributes ()

{
    local HomeFile
    local HomeAttrsString
    # local HomeAttrsArray
    # local HomeAttr

    if   [ -z "$1" ]
    then
        HomeFile=$(readlink -f "$(_home-manager_get-default-home-file)")
    else
        HomeFile="$1"
    fi

    HomeAttrsString=$(nix-instantiate --eval -E "let home = import ${HomeFile}; in (builtins.trace (builtins.toString (builtins.attrNames home)) null)" |& grep '^trace: ')
    HomeAttrsString="${HomeAttrsString#trace: }"

    echo "${HomeAttrsString}"

    # IFS=" " read -ar HomeAttrsArray <<< "${HomeAttrsString}"
    #
    # local HomeAttr
    # for HomeAttr in "${HomeAttrsArray[@]}"
    # do
    #     echo "${HomeAttr}"
    # done

}

# e.g.:
#
#   $ nix-instantiate --eval -E 'let home = import /home/sboo/configuration/configs/nixpkgs/home-attrs.nix; in (builtins.trace (builtins.toString (builtins.attrNames home)) null)' 1>/dev/null
#   trace: darwin linux
#
#   $ _home-manager_list-nix-attributes
#   linux darwin
#

#------------------------------------------------#

_home-manager_get-default-home-file ()

{
    local HomeFileDefault

    HomeFileDefault="$(_home-manager_xdg-get-config-home)/nixpkgs/home.nix"

    echo "${HomeFileDefault}"
}

# e.g.:
#
#   $ _home-manager_get-default-home-file
#   ~/.config/nixpkgs/home.nix
#

##################################################
# XDG-BaseDirs:

_home-manager_xdg-get-config-home () {

    echo "${XDG_CONFIG_HOME:-$HOME/.config}"

}

#------------------------------------------------#

_home-manager_xdg-get-data-home () {

    echo "${XDG_DATA_HOME:-$HOME/.local/share}"

}


#------------------------------------------------#
_home-manager_xdg-get-cache-home () {

    echo "${XDG_CACHE_HOME:-$HOME/.cache}"

}

##################################################

# shellcheck disable=SC2207
_home-manager_completions ()
{

    #--------------------------#

    local Subcommands
    Subcommands=( "help" "edit" "option" "build" "instantiate" "switch" "generations" "remove-generations" "expire-generations" "packages" "news" "uninstall" )

    # ^ « home-manager »'s subcommands.

    #--------------------------#

    local Options
    Options=( "-f" "--file" "-b" "-A" "-I" "-h" "--help" "-n" "--dry-run" "-v" "--verbose" \
              "--cores" "--debug" "--impure" "--keep-failed" "--keep-going" "-j" "--max-jobs" "--no-substitute" "--show-trace" "--substitute")

    # ^ « home-manager »'s options.

    #--------------------------#

    local CurrentWord
    CurrentWord="${COMP_WORDS[$COMP_CWORD]}"

    # ^ the word currently being completed

    local PreviousWord
    if [ "$COMP_CWORD" -ge 1 ]
    then
        PreviousWord="${COMP_WORDS[COMP_CWORD-1]}"
    else
        PreviousWord=""
    fi

    # ^ the word to the left of the current word.
    #
    #   e.g. in « home-manager -v -f ./<TAB> »:
    #
    #       PreviousWord="-f"
    #       CurrentWord="./"

    #--------------------------#

    COMPREPLY=()

    case "$PreviousWord" in

        "-f"|"--file")

            COMPREPLY+=( $( compgen -A file -- "$CurrentWord") )
            ;;

        "-I")

            COMPREPLY+=( $( compgen -A directory -- "$CurrentWord") )
            ;;

        "-A")

            # shellcheck disable=SC2119
            COMPREPLY+=( $( compgen -W "$(_home-manager_list-nix-attributes)" -- "$CurrentWord") )
            ;;

        "remove-generations")

            COMPREPLY+=( $( compgen -W "$(_home-manager_list-generation-identifiers)" -- "$CurrentWord" ) )
            ;;

        *)

            COMPREPLY+=( $( compgen -W "${Subcommands[*]}" -- "$CurrentWord" ) )
            COMPREPLY+=( $( compgen -W "${Options[*]}" -- "$CurrentWord" ) )
            ;;

    esac

    #--------------------------#
}

##################################################

complete -F _home-manager_completions -o default home-manager

#complete -W "help edit option build switch generations remove-generations expire-generations packages news" home-manager
