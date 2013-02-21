{-# LANGUAGE ImplicitParams #-}

-- Copy language L = { (w,w) | w € {a,b}^* }
module ADP.Tests.CopyTwoTrackExample where

import ADP.Debug
import ADP.Multi.SimpleParsers
import ADP.Multi.Combinators
import ADP.Multi.Tabulation
import ADP.Multi.Helpers
import ADP.Multi.Rewriting
                                 
type CopyTT_Algebra alphabet answer = (
  (EPS,EPS) -> answer,                      -- nil
  alphabet -> alphabet -> answer -> answer  -- copy
  )

data Start = Nil
           | Copy Char Char Start
           deriving (Eq, Show)

enum :: CopyTT_Algebra Char Start
enum = (nil,copy) where
   nil _ = Nil
   copy  = Copy
   
prettyprint :: CopyTT_Algebra Char (String,String)
prettyprint = (nil,copy) where
   nil _ = ("","")
   copy c1 c2 (l,r) = ([c1] ++ l,[c2] ++ r) 

-- (count of a's, count of b's)
countABs :: CopyTT_Algebra Char (Int,Int)
countABs = (nil,copy) where
   nil _                = (0,0)
   copy 'a' 'a' (c1,c2) = (c1+1,c2)
   copy 'b' 'b' (c1,c2) = (c1,c2+1)
  
   
copyTTGr :: YieldAnalysisAlgorithm Dim2 -> RangeConstructionAlgorithm Dim2 
         -> CopyTT_Algebra Char answer -> (String,String) -> [answer]
copyTTGr _ _ _ inp | trace ("running copyTTGr on " ++ show inp) False = undefined
copyTTGr yieldAlg2 rangeAlg2 algebra (inp1,inp2) =
  -- These implicit parameters are used by >>>.
  -- They were introduced to allow for exchanging the algorithms and
  -- they were made implicit so that they don't ruin our nice syntax.
  let ?yieldAlg2 = yieldAlg2
      ?rangeAlg2 = rangeAlg2
  in let
  
  (nil,copy) = algebra
  
  rewriteCopy [a',a'',c1,c2] = ([a',c1],[a'',c2])
  c = tabulated2 $
      copy <<< 'a' ~~~ 'a' ~~~|| c >>>|| rewriteCopy |||
      copy <<< 'b' ~~~ 'b' ~~~|| c >>>|| rewriteCopy |||
      nil   <<< (EPS,EPS) >>>|| id2
      
  z = mkTwoTrack inp1 inp2
  tabulated2 = table2 z
  
  in axiomTwoTrack z inp1 inp2 c