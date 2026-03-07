# CLAUDE.md

## Before Starting Any Task

Read these files to understand the project:
- `docs/design.md` — original design spec
- `docs/implementation.md` — what's been built and how

## Project Overview

`finite-table` is a Haskell library providing `Table i a`, a total array-like
container indexed by a finite `(Bounded, Enum)` type, backed by `Vector`.

Two modules:
- `Data.FiniteTable` — boxed, unconstrained element type
- `Data.FiniteTable.Unboxed` — unboxed, requires `Unbox a`

## Build Environment

This project uses Nix. All build/test commands must be run as:

    nix-shell --run "<command>"

For example:

    nix-shell --run "cabal build"
    nix-shell --run "cabal test"

GHC version: 9.10.3

## Key Files

- `finite-table.cabal` — package definition
- `src/Data/FiniteTable.hs` — boxed module
- `src/Data/FiniteTable/Unboxed.hs` — unboxed module
- `test/Spec.hs` — Hspec test suite (38 tests)
