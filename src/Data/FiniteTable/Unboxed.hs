{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Data.FiniteTable.Unboxed
  ( Table
  , tabulate
  , index
  , el
  , map
  , imap
  , foldMap
  , ifoldMap
  , traverse
  , itraverse
  ) where

import Prelude hiding (map, foldMap, traverse)
import qualified Prelude
import Control.Lens (Lens')
import qualified Data.Vector.Unboxed as V
import qualified Data.Vector.Unboxed.Mutable as MV
import Data.Vector.Unboxed (Vector, Unbox)

-- | A total container indexed by a finite, bounded, enumerated type,
-- backed by an unboxed vector.
newtype Table i a = Table (Vector a)

instance (Show a, Unbox a) => Show (Table i a) where
  showsPrec d (Table v) = showParen (d > 10) $
    showString "Table " . showsPrec 11 (V.toList v)

instance (Eq a, Unbox a) => Eq (Table i a) where
  Table a == Table b = a == b

instance (Ord a, Unbox a) => Ord (Table i a) where
  compare (Table a) (Table b) = compare a b

-- | The number of inhabitants of a bounded enum type.
size :: forall i. (Bounded i, Enum i) => Int
size = fromEnum (maxBound :: i) - fromEnum (minBound :: i) + 1

-- | Build a table by applying a function to each index value.
tabulate :: forall i a. (Bounded i, Enum i, Unbox a) => (i -> a) -> Table i a
tabulate f = Table $ V.generate (size @i) (f . toEnum . (+ fromEnum (minBound :: i)))

-- | Look up the value at a given index.
index :: forall i a. (Bounded i, Enum i, Unbox a) => Table i a -> i -> a
index (Table v) i = V.unsafeIndex v (fromEnum i - fromEnum (minBound :: i))

-- | A total lens into the element at a given index.
el :: forall i a. (Bounded i, Enum i, Unbox a) => i -> Lens' (Table i a) a
el i f (Table v) = (\a -> Table (V.modify (\mv -> MV.unsafeWrite mv idx a) v)) <$> f (V.unsafeIndex v idx)
  where
    idx = fromEnum i - fromEnum (minBound :: i)

toIndex :: forall i. (Bounded i, Enum i) => Int -> i
toIndex n = toEnum (n + fromEnum (minBound :: i))

-- | Map a function over all values.
map :: (Unbox a, Unbox b) => (a -> b) -> Table i a -> Table i b
map f (Table v) = Table (V.map f v)

-- | Map a function over all values with access to the index.
imap :: (Bounded i, Enum i, Unbox a, Unbox b) => (i -> a -> b) -> Table i a -> Table i b
imap f (Table v) = Table $ V.imap (f . toIndex) v

-- | Fold all values with a monoidal function.
foldMap :: (Unbox a, Monoid m) => (a -> m) -> Table i a -> m
foldMap f (Table v) = V.foldr (mappend . f) mempty v

-- | Fold all values with access to the index.
ifoldMap :: (Bounded i, Enum i, Unbox a, Monoid m) => (i -> a -> m) -> Table i a -> m
ifoldMap f (Table v) = V.ifoldr (\i a acc -> f (toIndex i) a <> acc) mempty v

-- | Traverse all values.
traverse :: (Unbox a, Unbox b, Applicative f) => (a -> f b) -> Table i a -> f (Table i b)
traverse f (Table v) = Table . V.fromListN (V.length v) <$> Prelude.traverse f (V.toList v)

-- | Traverse all values with access to the index.
itraverse :: (Bounded i, Enum i, Unbox a, Unbox b, Applicative f) => (i -> a -> f b) -> Table i a -> f (Table i b)
itraverse f (Table v) = Table . V.fromListN (V.length v) <$> Prelude.traverse (\(i, a) -> f (toIndex i) a) (zip [0..] (V.toList v))

instance (Bounded i, Enum i, Unbox a, Semigroup a) => Semigroup (Table i a) where
  Table a <> Table b = Table (V.zipWith (<>) a b)

instance (Bounded i, Enum i, Unbox a, Monoid a) => Monoid (Table i a) where
  mempty = tabulate (const mempty)
