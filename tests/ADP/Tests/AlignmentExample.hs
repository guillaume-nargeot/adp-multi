-- | Needleman/Wunsch global alignment of two sequences
module ADP.Tests.AlignmentExample where

import ADP.Debug
import ADP.Multi.All
import ADP.Multi.Rewriting.All
                                 
type Alignment_Algebra alphabet answer = (
  (EPS,EPS) -> answer,                      -- nil
  alphabet -> answer -> answer,             -- del
  alphabet -> answer -> answer,             -- ins
  alphabet -> alphabet -> answer -> answer, -- match
  [answer] -> [answer]                      -- h
  )
  
infixl ***
(***) :: (Eq b, Eq c) => Alignment_Algebra a b -> Alignment_Algebra a c -> Alignment_Algebra a (b,c)
alg1 *** alg2 = (nil,del,ins,match,h) where
   (nil',del',ins',match',h') = alg1
   (nil'',del'',ins'',match'',h'') = alg2
   
   nil a = (nil' a, nil'' a)
   del a (s1,s2) = (del' a s1, del'' a s2)
   ins a (s1,s2) = (ins' a s1, ins'' a s2)
   match a b (s1,s2) = (match' a b s1, match'' a b s2)
   h xs = [ (x1,x2) |
            x1 <- h'  [ y1 | (y1,_)  <- xs]
          , x2 <- h'' [ y2 | (y1,y2) <- xs, y1 == x1]
          ]

data Start = Nil
           | Del Char Start 
           | Ins Char Start
           | Match Char Char Start
           deriving (Eq, Show)

enum :: Alignment_Algebra Char Start
enum = (\_ -> Nil,Del,Ins,Match,id)

count :: Alignment_Algebra Char Int
count = (nil,del,ins,match,h) where
  nil _ = 1
  del _ s = s
  ins _ s = s
  match _ _ s = s
  h [] = []
  h x = [sum x]

unit :: Alignment_Algebra Char Int
unit = (nil,del,ins,match,h) where
  nil _ = 0
  del _ s = s-1
  ins _ s = s-1
  match a b s = if (a==b) then s+1 else s-1
  h [] = []
  h x = [maximum x]

      
alignmentGr :: Alignment_Algebra Char answer -> (String,String) -> [answer]
alignmentGr _ inp | trace ("running alignmentGr on " ++ show inp) False = undefined
alignmentGr algebra (inp1,inp2) =
  let
  (nil,del,ins,match,h) = algebra
  
  rewriteDel, rewriteIns, rewriteMatch :: Dim2
  
  rewriteDel [c,a1,a2] = ([c,a1],[a2])
  rewriteIns [c,a1,a2] = ([a1],[c,a2])
  rewriteMatch [c1,c2,a1,a2] = ([c1,a1],[c2,a2])
  
  a = tabulated2 $
      yieldSize2 (0,Nothing) (0,Nothing) $
      nil   <<< (EPS,EPS)                 >>> id2 |||
      del   <<< anychar ~~~ a             >>> rewriteDel |||
      ins   <<< anychar ~~~ a             >>> rewriteIns |||
      match <<< anychar ~~~ anychar ~~~ a >>> rewriteMatch
      ... h
      
  z = mkTwoTrack inp1 inp2
  tabulated2 = table2 z
  
  in axiomTwoTrack z inp1 inp2 a