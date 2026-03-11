{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeApplications #-}

module Main (main) where

import Data.FiniteTable (Table)
import qualified Data.FiniteTable as T
import qualified Data.FiniteTable.Unboxed as U
import Control.Lens (view, set, over, imap, ifoldMap, itraverse, iview, iover)
import Data.Monoid (Sum(..))
import Test.Hspec

data ABC = A | B | C
  deriving (Eq, Ord, Enum, Bounded, Show)

abc :: Table ABC String
abc = T.tabulate show

main :: IO ()
main = hspec $ do
  boxedTests
  unboxedTests

boxedTests :: Spec
boxedTests = describe "Data.FiniteTable (boxed)" $ do
  describe "tabulate/index" $ do
    it "round-trips through all indices" $ do
      T.index abc A `shouldBe` "A"
      T.index abc B `shouldBe` "B"
      T.index abc C `shouldBe` "C"

    it "works with Bool" $ do
      let t = T.tabulate @Bool not
      T.index t False `shouldBe` True
      T.index t True `shouldBe` False

    it "works with a single-element type" $ do
      let t = T.tabulate @() (\() -> 42 :: Int)
      T.index t () `shouldBe` 42

  describe "el (lens)" $ do
    it "views an element" $ do
      view (T.el B) abc `shouldBe` "B"

    it "sets an element" $ do
      let t = set (T.el B) "Changed!" abc
      T.index t A `shouldBe` "A"
      T.index t B `shouldBe` "Changed!"
      T.index t C `shouldBe` "C"

    it "modifies an element with over" $ do
      let t = over (T.el A) (++ "!") abc
      T.index t A `shouldBe` "A!"
      T.index t B `shouldBe` "B"

    it "iview returns the index and value" $ do
      iview (T.el B) abc `shouldBe` (B, "B")

    it "iover provides the index to the modifier" $ do
      let t = iover (T.el A) (\i s -> show i ++ ":" ++ s) abc
      T.index t A `shouldBe` "A:A"
      T.index t B `shouldBe` "B"

  describe "Functor" $ do
    it "fmap applies to all elements" $ do
      let t = fmap length abc
      T.index t A `shouldBe` 1
      T.index t B `shouldBe` 1
      T.index t C `shouldBe` 1

  describe "Foldable" $ do
    it "folds all elements" $ do
      foldMap (Sum . length) abc `shouldBe` Sum 3

    it "length returns the number of indices" $ do
      length abc `shouldBe` 3

    it "toList returns all values in order" $ do
      foldr (:) [] abc `shouldBe` ["A", "B", "C"]

  describe "Traversable" $ do
    it "traverse with Just succeeds" $ do
      let t = traverse (\s -> Just (s ++ "!")) abc
      t `shouldBe` Just (T.tabulate (\i -> show i ++ "!"))

    it "traverse with Nothing short-circuits" $ do
      let t = traverse (\s -> if s == "B" then Nothing else Just s) abc
      t `shouldBe` (Nothing :: Maybe (Table ABC String))

  describe "Applicative" $ do
    it "pure creates a constant table" $ do
      let t = Prelude.pure "x" :: Table ABC String
      T.index t A `shouldBe` "x"
      T.index t B `shouldBe` "x"
      T.index t C `shouldBe` "x"

    it "<*> applies functions element-wise" $ do
      let fs = T.tabulate @ABC $ \case A -> (++ "!"); B -> (++ "?"); C -> reverse
      let t = fs <*> abc
      T.index t A `shouldBe` "A!"
      T.index t B `shouldBe` "B?"
      T.index t C `shouldBe` "C"

    it "liftA2 combines element-wise" $ do
      let t = liftA2 (++) abc (T.tabulate (\i -> ":" ++ show i))
      T.index t A `shouldBe` "A:A"
      T.index t B `shouldBe` "B:B"

  describe "Semigroup" $ do
    it "combines element-wise" $ do
      let t = abc <> T.tabulate (\i -> "!" ++ show i)
      T.index t A `shouldBe` "A!A"
      T.index t B `shouldBe` "B!B"

  describe "Monoid" $ do
    it "mempty contains monoidal identities" $ do
      let t = mempty :: Table ABC String
      T.index t A `shouldBe` ""
      T.index t B `shouldBe` ""

    it "mempty <> x == x" $ do
      (mempty <> abc) `shouldBe` abc

  describe "FunctorWithIndex" $ do
    it "imap provides the index" $ do
      let t = imap (\i s -> show i ++ ":" ++ s) abc
      T.index t A `shouldBe` "A:A"
      T.index t B `shouldBe` "B:B"
      T.index t C `shouldBe` "C:C"

  describe "FoldableWithIndex" $ do
    it "ifoldMap provides the index" $ do
      let result = ifoldMap (\i s -> [(i, s)]) abc
      result `shouldBe` [(A, "A"), (B, "B"), (C, "C")]

  describe "TraversableWithIndex" $ do
    it "itraverse provides the index" $ do
      let t = itraverse (\i s -> Just (show i ++ ":" ++ s)) abc
      fmap (\t' -> T.index t' B) t `shouldBe` Just "B:B"

  describe "Eq/Show" $ do
    it "equal tables are equal" $ do
      T.tabulate @ABC show `shouldBe` abc

    it "unequal tables are not equal" $ do
      set (T.el A) "X" abc `shouldNotBe` abc

unboxedTests :: Spec
unboxedTests = describe "Data.FiniteTable.Unboxed" $ do
  let uabc = U.tabulate @ABC fromEnum :: U.Table ABC Int

  describe "tabulate/index" $ do
    it "round-trips through all indices" $ do
      U.index uabc A `shouldBe` 0
      U.index uabc B `shouldBe` 1
      U.index uabc C `shouldBe` 2

    it "works with Bool" $ do
      let t = U.tabulate @Bool (\b -> if b then 1 else 0 :: Int)
      U.index t False `shouldBe` 0
      U.index t True `shouldBe` 1

    it "works with a single-element type" $ do
      let t = U.tabulate @() (\() -> 42 :: Int)
      U.index t () `shouldBe` 42

  describe "el (lens)" $ do
    it "views an element" $ do
      view (U.el B) uabc `shouldBe` 1

    it "sets an element" $ do
      let t = set (U.el B) 99 uabc
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 99
      U.index t C `shouldBe` 2

    it "modifies an element with over" $ do
      let t = over (U.el A) (* 10) uabc
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 1

    it "iview returns the index and value" $ do
      iview (U.el B) uabc `shouldBe` (B, 1)

    it "iover provides the index to the modifier" $ do
      let t = iover (U.el C) (\i v -> fromEnum i + v) uabc
      U.index t C `shouldBe` 4
      U.index t A `shouldBe` 0

  describe "map" $ do
    it "maps a function over all elements" $ do
      let t = U.map (* 2) uabc
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 2
      U.index t C `shouldBe` 4

  describe "foldMap" $ do
    it "folds all elements" $ do
      U.foldMap Sum uabc `shouldBe` Sum 3

  describe "imap" $ do
    it "provides the index" $ do
      let t = U.imap (\i v -> fromEnum i + v) uabc
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 2
      U.index t C `shouldBe` 4

  describe "ifoldMap" $ do
    it "provides the index" $ do
      let result = U.ifoldMap (\i v -> [(i, v)]) uabc
      result `shouldBe` [(A, 0), (B, 1), (C, 2)]

  describe "traverse" $ do
    it "traverse with Just succeeds" $ do
      let t = U.traverse (\v -> Just (v + 10)) uabc
      fmap (\t' -> U.index t' B) t `shouldBe` Just 11

    it "traverse with Nothing short-circuits" $ do
      let t = U.traverse (\v -> if v == 1 then Nothing else Just v) uabc
      t `shouldBe` (Nothing :: Maybe (U.Table ABC Int))

  describe "itraverse" $ do
    it "provides the index" $ do
      let t = U.itraverse (\i v -> Just (fromEnum i * 10 + v)) uabc
      fmap (\t' -> U.index t' C) t `shouldBe` Just 22

  describe "pure/zipWith" $ do
    it "pure creates a constant table" $ do
      let t = U.pure @ABC 42 :: U.Table ABC Int
      U.index t A `shouldBe` 42
      U.index t B `shouldBe` 42
      U.index t C `shouldBe` 42

    it "zipWith combines element-wise" $ do
      let t = U.zipWith (+) uabc (U.tabulate @ABC ((*10) . fromEnum))
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 11
      U.index t C `shouldBe` 22

    it "zipWith is symmetric" $ do
      let t = U.zipWith (*) uabc uabc
      U.index t A `shouldBe` 0
      U.index t B `shouldBe` 1
      U.index t C `shouldBe` 4

  describe "Semigroup" $ do
    it "combines element-wise" $ do
      let t = U.tabulate @ABC (Sum . fromEnum) <> U.tabulate @ABC (Sum . (* 10) . fromEnum)
      U.index t B `shouldBe` Sum 11

  describe "Monoid" $ do
    it "mempty contains monoidal identities" $ do
      let t = mempty :: U.Table ABC (Sum Int)
      U.index t A `shouldBe` Sum 0

    it "mempty <> x == x" $ do
      let t = U.tabulate @ABC (Sum . fromEnum)
      (mempty <> t) `shouldBe` t

  describe "Eq/Ord/Show" $ do
    it "equal tables are equal" $ do
      U.tabulate @ABC fromEnum `shouldBe` uabc

    it "unequal tables are not equal" $ do
      set (U.el A) 99 uabc `shouldNotBe` uabc
