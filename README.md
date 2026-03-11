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

-- Total indexed lens
import Control.Lens

view (el Red) colorTable              -- "Red"
set (el Blue) "Azul" colorTable       -- updated table
over (el Green) (++ "!") colorTable   -- modified table
iview (el Red) colorTable             -- (Red, "Red")
iover (el Red) (\i s -> show i ++ ":" ++ s) colorTable  -- modified with index
```

## Modules

- **`Data.FiniteTable`** — Boxed variant. No constraints on the element type.
  Provides `Functor`, `Foldable`, `Traversable`, `Applicative`,
  `FunctorWithIndex`, `FoldableWithIndex`, `TraversableWithIndex`, `Semigroup`,
  and `Monoid` instances. The `Applicative` instance is zippy: `pure` creates a
  constant table and `<*>`/`liftA2` combine element-wise.

- **`Data.FiniteTable.Unboxed`** — Unboxed variant. Requires `Unbox a` on
  elements. Since `Functor`/`Foldable`/`Traversable`/`Applicative` cannot have
  constrained element types, equivalent functionality is provided as standalone
  functions: `pure`, `zipWith`, `map`, `imap`, `foldMap`, `ifoldMap`,
  `traverse`, `itraverse`.

Both modules export the same core API:

- `tabulate :: (Bounded i, Enum i) => (i -> a) -> Table i a`
- `index :: (Bounded i, Enum i) => Table i a -> i -> a`
- `el :: (Bounded i, Enum i) => i -> IndexedLens' i (Table i a) a`

## Building

This project uses Nix:

```sh
nix-shell --run "cabal build"
nix-shell --run "cabal test"
```
