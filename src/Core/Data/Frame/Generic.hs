{-# language
    DataKinds
  , FlexibleContexts
  , GADTs 
  , LambdaCase 
  , TypeOperators
  , ScopedTypeVariables
#-}
{-# OPTIONS_GHC -Wall #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Core.Data.Frame.Generic
-- Description :  Populate dataframes with generically-encoded data
-- Copyright   :  (c) Marco Zocca (2019)
-- License     :  MIT
-- Maintainer  :  ocramz fripost org
-- Stability   :  experimental
-- Portability :  GHC
--
-- Generic encoding of algebraic datatypes, using 'generics-sop'
--
-----------------------------------------------------------------------------
module Core.Data.Frame.Generic (
    gToRow, gToTable,
    -- * Exceptione
    DataException(..)
  ) where

-- import Data.Char (toLower)
-- import Data.Maybe (fromMaybe)
-- import Data.Fix (Fix(..), cata, ana)
-- import Control.Arrow (second)

-- import Generics.SOP hiding (fromList) -- (Generic(..), All, Code)
-- import Generics.SOP.NP (cpure_NP)
-- import Generics.SOP.Constraint (SListIN)
-- import Generics.SOP.GGP   -- (GCode, GDatatypeInfo, GFrom, gdatatypeInfo, gfrom)
-- import Generics.SOP.NP
-- import qualified GHC.Generics as G

import Data.Typeable (Typeable)
-- import Data.Dynamic

import Control.Exception (Exception(..))
import Control.Monad.Catch (MonadThrow(..))
-- import Control.Monad.State (State(..), runState, get, put, modify)

-- import qualified Data.Foldable as F (Foldable(..)) 
-- import qualified Data.Text as T
-- -- import qualified Data.Vector as V
-- -- import qualified Data.Map as M
-- import qualified Data.HashMap.Strict as HM
-- import Data.Hashable (Hashable(..))

import Core.Data.Frame (Row, Frame, fromList, mkRow)
import qualified Data.Generics.Encode.Val as AV (gflatten, ToVal, TC, VP)


-- $setup
-- >>> :set -XDeriveGeneric
-- >>> import qualified GHC.Generics as G
-- >>> import qualified Data.Generics.Encode.Val as AV
-- >>> data P1 = P1 Int Char deriving (Eq, Show, G.Generic)
-- >>> instance AV.ToVal P1
-- >>> data P2 = P2 { p2i :: Int, p2c :: Char } deriving (Eq, Show, G.Generic)
-- >>> instance AV.ToVal P2
-- >>> data Q = Q (Maybe Int) (Either Double Char) deriving (Eq, Show, G.Generic)
-- >>> instance AV.ToVal Q

-- | Populate a 'Frame' with the generic encoding of the row data and throws a 'DataException' if the input data is malformed.
--
-- For example, a list of records having two fields each will produce a dataframe with two columns, having the record field names as column labels.
--
-- @
-- data P1 = P1 Int Char deriving (Eq, Show, 'G.Generic')
-- instance 'AV.ToVal' P1
-- 
-- data P2 = P2 { p2i :: Int, p2c :: Char } deriving (Eq, Show, Generic)
-- instance ToVal P2
--
-- data Q = Q (Maybe Int) (Either Double Char) deriving (Eq, Show, Generic)
-- instance ToVal Q
-- @
--
-- >>> gToTable [P1 42 'z']
-- Frame {tableRows = [([TC "P1" "_1"],VPChar 'z'),([TC "P1" "_0"],VPInt 42)] :| []}
-- 
-- >>> gToTable [P2 42 'z']
-- Frame {tableRows = [([TC "P2" "p2c"],VPChar 'z'),([TC "P2" "p2i"],VPInt 42)] :| []}
--
-- Test using 'Maybe' and 'Either' record fields :
--
-- >>> gToTable [Q (Just 42) (Left 1.2), Q Nothing (Right 'b')]
-- Frame {tableRows = [([TC "Q" "_1",TC "Either" "Left"],VPDouble 1.2),([TC "Q" "_0",TC "Maybe" "Just"],VPInt 42)] :| [[([TC "Q" "_1",TC "Either" "Right"],VPChar 'b')]]}
--
-- NB: as the last example above demonstrates, 'Nothing' values are not inserted in the rows, which can be used to encode missing data features.
gToTable :: (MonadThrow m, AV.ToVal a) =>
            [a]
         -> m (Frame (Row [AV.TC] AV.VP))
gToTable ds
  | null ds = throwM NoDataE 
  | otherwise = pure $ fromList $ map (mkRow . AV.gflatten) ds


gToRow :: AV.ToVal a => a -> Row [AV.TC] AV.VP
gToRow = mkRow . AV.gflatten


-- | Exceptions related to the input data
data DataException =
    -- AnonRecordE -- ^ Anonymous records not implemented yet
    NoDataE     -- ^ Dataset has 0 rows
  deriving (Eq, Typeable)
instance Show DataException where
  show = \case
    -- AnonRecordE -> "Anonymous records not implemented yet"
    NoDataE -> "The dataset has 0 rows"
instance Exception DataException

