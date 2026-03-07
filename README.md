# finite-table

Total array-like containers indexed by finite enumerated types.

`Table i a` is a complete mapping from every value of an index type `i` to a
value of type `a`, backed by a `Vector`. Since the index type is `Bounded` and
`Enum`, every lookup is total — no `Maybe`, no exceptions.

## Usage

```haskell
import Data.FiniteTable

data Color = Red | Green | Blue
  deriving (Eq, Ord, Enum, Bounded, Show)

colorTable :: Table Color String
colorTable = tabulate show

-- Total lookup — always succeeds
index colorTable Green  -- "Green"

-- Total lens
import Control.Lens

view (el Red) colorTable              -- "Red"
set (el Blue) "Azul" colorTable       -- updated table
over (el Green) (++ "!") colorTable   -- modified table
```

## Modules

- **`Data.FiniteTable`** — Boxed variant. No constraints on the element type.
  Provides `Functor`, `Foldable`, `Traversable`, `FunctorWithIndex`,
  `FoldableWithIndex`, `TraversableWithIndex`, `Semigroup`, and `Monoid`
  instances.

- **`Data.FiniteTable.Unboxed`** — Unboxed variant. Requires `Unbox a` on
  elements. Since `Functor`/`Foldable`/`Traversable` cannot have constrained
  element types, equivalent functionality is provided as standalone functions:
  `map`, `imap`, `foldMap`, `ifoldMap`, `traverse`, `itraverse`.

Both modules export the same core API:

- `tabulate :: (Bounded i, Enum i) => (i -> a) -> Table i a`
- `index :: (Bounded i, Enum i) => Table i a -> i -> a`
- `el :: (Bounded i, Enum i) => i -> Lens' (Table i a) a`

## Building

This project uses Nix:

```sh
nix-shell --run "cabal build"
nix-shell --run "cabal test"
```
