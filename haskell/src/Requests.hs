{-# LANGUAGE DeriveAnyClass #-}

module Requests where

import Data.Aeson
import Data.Text
import GHC.Generics

-- types for constructing a request to VS Code Marketplace
data Criterion = Criterion
  { filterType :: Int
  , value :: Text
  }
  deriving stock (Generic)
  deriving anyclass (ToJSON)

data Filter = Filter
  { criteria :: [Criterion]
  , pageNumber :: Int
  , pageSize :: Int
  , sortBy :: Int
  , sortOrder :: Int
  }
  deriving stock (Generic)
  deriving anyclass (ToJSON)

data Req = Req
  { filters :: [Filter]
  , assetTypes :: [String]
  , flags :: Int
  }
  deriving stock (Generic)
  deriving anyclass (ToJSON)
