{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Data.FiniteTable
  ( Table
  , tabulate
  , index
  , el
  ) where

import Control.Lens (IndexedLens', indexed, FunctorWithIndex(..), FoldableWithIndex(..), TraversableWithIndex(..))
import Data.Vector (Vector)
import qualified Data.Vector as V

-- | A total container indexed by a finite, bounded, enumerated type.
newtype Table i a = Table (Vector a)
  deriving (Eq, Ord, Show)

-- | The number of inhabitants of a bounded enum type.
size :: forall i. (Bounded i, Enum i) => Int
size = fromEnum (maxBound :: i) - fromEnum (minBound :: i) + 1

-- | Build a table by applying a function to each index value.
tabulate :: forall i a. (Bounded i, Enum i) => (i -> a) -> Table i a
tabulate f = Table $ V.generate (size @i) (f . toEnum . (+ fromEnum (minBound :: i)))

-- | Look up the value at a given index.
index :: forall i a. (Bounded i, Enum i) => Table i a -> i -> a
index (Table v) i = V.unsafeIndex v (fromEnum i - fromEnum (minBound :: i))

-- | A total indexed lens into the element at a given index.
el :: forall i a. (Bounded i, Enum i) => i -> IndexedLens' i (Table i a) a
el i f (Table v) = (\a -> Table (V.unsafeUpd v [(idx, a)])) <$> indexed f i (V.unsafeIndex v idx)
  where
    idx = fromEnum i - fromEnum (minBound :: i)

toIndex :: forall i. (Bounded i, Enum i) => Int -> i
toIndex n = toEnum (n + fromEnum (minBound :: i))

instance (Bounded i, Enum i) => Applicative (Table i) where
  pure a = tabulate (const a)
  Table fs <*> Table xs = Table (V.zipWith ($) fs xs)
  liftA2 f (Table as) (Table bs) = Table (V.zipWith f as bs)

instance Functor (Table i) where
  fmap f (Table v) = Table (fmap f v)

instance Foldable (Table i) where
  foldMap f (Table v) = foldMap f v
  foldr f z (Table v) = foldr f z v
  length (Table v) = length v

instance (Bounded i, Enum i) => Traversable (Table i) where
  traverse f (Table v) = Table <$> traverse f v

instance Semigroup a => Semigroup (Table i a) where
  Table a <> Table b = Table (V.zipWith (<>) a b)

instance (Bounded i, Enum i, Monoid a) => Monoid (Table i a) where
  mempty = tabulate (const mempty)

instance (Bounded i, Enum i) => FunctorWithIndex i (Table i) where
  imap f (Table v) = Table $ V.imap (f . toIndex) v

instance (Bounded i, Enum i) => FoldableWithIndex i (Table i) where
  ifoldMap f (Table v) = V.ifoldr (\i a acc -> f (toIndex i) a <> acc) mempty v

instance (Bounded i, Enum i) => TraversableWithIndex i (Table i) where
  itraverse f (Table v) = Table . V.fromListN (V.length v) <$> traverse (\(i, a) -> f (toIndex i) a) (zip [0..] (V.toList v))
