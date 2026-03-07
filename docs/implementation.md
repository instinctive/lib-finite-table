# Implementation Notes

## Project Structure

```
finite-table.cabal
default.nix
src/
  Data/
    FiniteTable.hs          -- Boxed variant
    FiniteTable/
      Unboxed.hs            -- Unboxed variant
test/
  Spec.hs                   -- Hspec test suite
```

## Package: `finite-table`

Builds with GHC 9.10.3 via Nix. Depends on `base`, `vector`, and `lens`.

## `Data.FiniteTable` (boxed)

`Table i a` is a newtype over `Data.Vector.Vector a`. The index type `i` must
be `Bounded` and `Enum`; the element type `a` is unconstrained.

### Exports

- `Table i a` — the type (constructor not exported)
- `tabulate :: (Bounded i, Enum i) => (i -> a) -> Table i a`
- `index :: (Bounded i, Enum i) => Table i a -> i -> a`
- `el :: (Bounded i, Enum i) => i -> Lens' (Table i a) a` — total lens

### Instances

- `Eq, Ord, Show` (derived)
- `Functor, Foldable, Traversable`
- `Semigroup` (element-wise, requires `Semigroup a`)
- `Monoid` (via `tabulate (const mempty)`, requires `Monoid a`)
- `FunctorWithIndex i, FoldableWithIndex i, TraversableWithIndex i` (from `lens`)

### Implementation details

- Index translation: `fromEnum i - fromEnum (minBound :: i)` gives a 0-based
  vector index. This handles types like `data D = X | Y | Z` (where
  `minBound` maps to 0) and also types with non-zero `fromEnum` for `minBound`.
- Uses `V.unsafeIndex` and `V.unsafeUpd` since totality is guaranteed by the
  `Bounded`/`Enum` constraint.
- Most instances delegate directly to the underlying `Vector` instances.

## `Data.FiniteTable.Unboxed`

Same API as the boxed variant, but backed by `Data.Vector.Unboxed.Vector`.
All operations require an `Unbox a` constraint.

### Differences from boxed

- Cannot provide `Functor`, `Foldable`, `Traversable`, or the indexed
  typeclasses as instances, because those classes require unconstrained element
  types. Instead, standalone functions are exported: `map`, `imap`, `foldMap`,
  `ifoldMap`, `traverse`, `itraverse`.
- `Eq`, `Ord`, `Show` are manual instances (can't derive through the newtype
  due to the `Unbox` constraint).
- `el` uses `V.modify` with `MV.unsafeWrite` for the update (unboxed vectors
  don't have a list-based `unsafeUpd`).

## Test Suite

Hspec tests in `test/Spec.hs` covering both modules (38 tests total). Tests
exercise all exported functions and instances, including edge cases like
single-element index types (`()`) and `Bool`.
