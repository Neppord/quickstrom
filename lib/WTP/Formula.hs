{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}

module WTP.Formula where

import Control.Monad.Freer
import Control.Monad.Freer.Error
import Data.Text (Text)
import WTP.Query
import Prelude hiding (False, True)

data Assertion a where
  Equals :: (Show a, Eq a) => a -> Assertion a
  Contains :: Text -> Assertion Text
  Satisfies :: Show a => (a -> Bool) -> Assertion a

instance Show (Assertion a) where
  show = \case
    Equals expected -> "(Equals " <> show expected <> ")"
    Contains t -> "(Contains " <> show t <> ")"
    Satisfies _ -> "(Satisfies _)"

data Formula where
  True :: Formula
  Not :: Formula -> Formula
  Or :: Formula -> Formula -> Formula
  Until :: Formula -> Formula -> Formula
  Assert :: Eff '[Query, Error Text] a -> Assertion a -> Formula

withQueries :: forall m b. Monad m => (forall a. Eff '[Query, Error Text] a -> m b) -> Formula -> m [b]
withQueries f = \case
  True -> pure []
  Not p -> withQueries f p
  Or p q -> (<>) <$> withQueries f p <*> withQueries f q
  Until p q -> (<>) <$> withQueries f p <*> withQueries f q
  Assert q _ -> (: []) <$> f q

instance Show Formula where
  show = \case
    True -> "True"
    Not p -> "(Not " <> show p <> ")"
    Or p q -> "(Or " <> show p <> " " <> show q <> ")"
    Until p q -> "(Until " <> show p <> " " <> show q <> ")"
    Assert _ assertion -> "(Assert _ " <> show assertion <> ")"