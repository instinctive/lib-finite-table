# Design

For this project we will build a library for array-like containers over a
finite, enumerated, bounded index type. Let's call this container a `Table`.
`Table` should have instances for `Functor, Foldable, Traversable, Semigroup,
Monoid,` provide `index` and `tabulate`, and provide the indexed traversals for
the lens library: `FunctorWithIndex, FoldableWithIndex, TraversableWithIndex.`
Also provide `el` a total lens.

## Implementation

Use `Vector` as the underlying representation. Since this is a total structure,
use all the unsafe operations as we know we cannot be out of bounds.

Note that `Vector` already has most of these instances, so your implementation
should make use of that.

## Example

```haskell
import Data.FiniteTable
import Control.Lens

data MyIndex = A | B | C deriving (Eq,Ord,Enum,Bounded,Show,Generic)

myTable :: Table MyIndex String
myTable = tabulate show

-- Use the total `el` lens
updatedTable = myTable & el B .~ "Changed!"
```
