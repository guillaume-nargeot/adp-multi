{-# LANGUAGE ImplicitParams #-}

module ADP.Tests.NussinovExample where

import ADP.Multi.SimpleParsers
import ADP.Multi.Combinators
import ADP.Multi.Tabulation
import ADP.Multi.Helpers
import ADP.Multi.Rewriting
                                 
type Nussinov_Algebra alphabet answer = (
   EPS -> answer,                              -- nil
   alphabet -> answer,                         -- base
   alphabet -> answer   -> answer,             -- left
   answer   -> answer   -> answer,             -- right
   alphabet -> answer   -> alphabet -> answer, -- pair
   answer   -> answer   -> answer,             -- split
   [answer] -> [answer]                        -- h
   )
   
pairmax :: Nussinov_Algebra Char Int
pairmax = (nil,base,left,right,pair,split,h) where
    nil _       = 0
    base _      = undefined
    left _ x    = x
    right x _   = x
    pair _ x _  = x + 1
    split x y   = x + y
    h xs        = [maximum xs]
  
   
nussinov78 :: YieldAnalysisAlgorithm Dim1 -> RangeConstructionAlgorithm Dim1
           -> Nussinov_Algebra Char answer -> String -> [answer]
nussinov78 yieldAlg1 rangeAlg1 algebra inp =
  -- These implicit parameters are used by >>>.
  -- They were introduced to allow for exchanging the algorithms and
  -- they were made implicit so that they don't ruin our nice syntax.
  let ?yieldAlg1 = yieldAlg1
      ?rangeAlg1 = rangeAlg1
  in let
  
  (nil,base,left,right,pair,split,h) = algebra

  s = tabulated $
      nil <<< EPS >>>| id |||
      right <<<| s ~~~ b >>>| id |||
      split <<<| s ~~~ t >>>| id
      ... h

  t = tabulated $
      pair <<< 'a' ~~~| s ~~~ 'u' >>>| id |||
      pair <<< 'u' ~~~| s ~~~ 'a' >>>| id |||
      pair <<< 'c' ~~~| s ~~~ 'g' >>>| id |||
      pair <<< 'g' ~~~| s ~~~ 'c' >>>| id |||
      pair <<< 'g' ~~~| s ~~~ 'u' >>>| id |||
      pair <<< 'u' ~~~| s ~~~ 'g' >>>| id
  
  b = tabulated $
      base <<< 'a' >>>| id |||
      base <<< 'u' >>>| id |||
      base <<< 'c' >>>| id |||
      base <<< 'g' >>>| id
  
  z = mk inp
  tabulated = table1 z
  
  in axiom z s