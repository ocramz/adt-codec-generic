{-# language DeriveAnyClass #-}
{-# language DeriveGeneric #-}
{-# language OverloadedStrings #-}
{-# options_ghc -Wno-unused-imports #-}
module Main where

import Control.Applicative (Alternative)
import GHC.Generics (Generic)
import Data.Typeable
import Control.Monad.Catch

-- import Data.Hashable (Hashable)
-- import qualified Data.HashMap.Strict as HM
import qualified Data.Text as T

import Heidi
import Heidi.Data.Frame.Algorithms.GenericTrie (innerJoin)

-- import Lens.Micro ((^.), (%~), to, has)

import Prelude hiding (filter, lookup)

-- | Item
data Item a = Itm String a deriving (Eq, Show, Generic, Heidi)

-- | Purchase
data Purchase a = Pur {
    date :: Int
  , pers :: String
  , item :: String
  , qty :: a
  } deriving (Eq, Show, Generic, Heidi)

items :: [Item Double]
items = [i1, i2, i3] where
  i1 = Itm "computer" 1000
  i2 = Itm "car" 5000
  i3 = Itm "legal" 400

purchases :: [Purchase Double]
purchases = [p1, p2, p3, p4, p5] where
  p1 = Pur 7 "bob" "car" 1
  p2 = Pur 5 "alice" "car" 1
  p3 = Pur 4 "bob" "legal" 20
  p4 = Pur 3 "alice" "computer" 2
  p5 = Pur 1 "bob" "computer" 1


gItems, gPurchases :: Frame (Row [TC] VP)
gItems = encode items
gPurchases = encode purchases



-- FIXME now we use Traversal' rather than Decode

-- noLegal :: (MonadThrow f, Alternative f) =>
--            String
--         -> Frame (GTR.Row [TC] VP)
--         -> f (Frame (GTR.Row [TC] VP))
-- noLegal k = filterDecode dec where
--   dec r = r ^. GTR.text (keyN k) == "legal"

noLegal :: String -> Frame (Row [TC] VP) -> Frame (Row [TC] VP)
noLegal k = filter look
  where
    look = keep (text (keyN k)) (== "legal")

keyN, keyTyC :: String -> [TC]
keyN k = [mkTyN k]

keyTyC k = [mkTyCon k]


-- joinTables = innerJoin k1 k2 where
--   k1 = keyN ""
--   k2 = keyN ""
  



-- joinTables :: (Foldable t, Hashable v, Eq v) =>
--               t (Row [TC] v) -> t (Row [TC] v) -> Frame (Row [TC] v)
-- joinTables = innerJoin k1 k2 where
--   k1 = [TC "Itm" "_0"]
--   k2 = itemKey

























{-
Averaged across persons, excluding legal fees, how much money had each person spent by time 6?

item , price 
----------
computer , 1000 
car , 5000 
legal fees (1 hour) , 400

date , person , item-bought , units-bought 
------------------------------------
7 , bob , car , 1 
5 , alice , car , 1 
4 , bob , legal fees (1 hour) , 20 
3 , alice , computer , 2 
1 , bob , computer , 1 

It would be extra cool if you provided both an in-memory and a streaming solution.

Principles|operations it illustrates

Predicate-based indexing|filtering.
Merging (called "joining" in SQL).
Within- and across-group operations.
Sorting.
Accumulation (what Data.List calls "scanning").
Projection (both the "last row" and the "mean" operations).
Statistics (the "mean" operation).

Solution and proposed algorithm (it's possible you don't want to read this)

The answer is $4000. That's because by time 6, Bob had bought 1 computer ($1000) and 20 hours of legal work (excluded), while Alice had bought a car ($5000) and two computers ($2000). In total they had spent $8000, so the across-persons average is $4000.

One way to compute that would be to:

    Delete any purchase of legal fees.
    Merge price and purchase data.
    Compute a new column, "money-spent" = units-bought price.
    Group by person.
    Within each group: Sort by date in increasing order.
    Compute a new column, "accumulated-spending" = running total of money spent.
    Keep the last row with a date no greater than 6; drop all others.
    Across groups, compute the mean of accumulated spending.

-}





main :: IO ()
main = pure ()
