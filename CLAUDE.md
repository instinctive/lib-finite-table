# CLAUDE.md

## Before Starting Any Task

Read this file first to understand the design:
- `docs/design.md` — design for the library

## Build Environment

This project uses Nix. All build/test commands must be run as:

    nix-shell --run "<command>"

For example:

    nix-shell --run "cabal build"
    nix-shell --run "cabal test"
