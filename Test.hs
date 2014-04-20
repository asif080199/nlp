{-# OPTIONS_GHC -Wall #-}

module Test where

import Grammar
import Lexer
import Parser

isAmbiguous :: [Node] -> Bool
isAmbiguous =
  let
    isAmbiguous' [Node EOF _ _] = False
    isAmbiguous' (_ : _ : _) = True
    isAmbiguous' [Node (FullSentence _) _ children] =
        isAmbiguous' children
    isAmbiguous' _ = True
  in
    isAmbiguous' . extractSentences

isSingleSentence :: [Node] -> Bool
isSingleSentence = isSingleSentence' . extractSentences

-- Note: it's okay if the sentence is ambiguous, as long as all possible parses
-- result in a single sentence.
isSingleSentence' :: [Node] -> Bool
isSingleSentence' =
  let
    nodeIsSingleSentence' (Node (FullSentence _) _ [Node EOF _ _]) = True
    nodeIsSingleSentence' _ = False
  in
    all nodeIsSingleSentence'

-- I've gotten some example text appropriate for first grade reading levels from
-- http://www.superteacherworksheets.com/1st-comprehension.html

-- Text taken from the first grade reading comprehension worksheet at
-- http://www.superteacherworksheets.com/reading-comp/1st-ball-for-my-dog_TZZMD.pdf
text1 :: String
text1 = "my dog found a ball . it was a yellow ball . my dog loves to chew . he chewed the yellow ball . my dog found another ball . it was a red ball . my dog loves to play . he played with the red ball . my dog found another ball . it was a blue ball . my dog loves to run . he ran after the blue ball when I threw it ."
results1partial :: [Node]
results1partial = lexNodes text1
results1 :: [Node]
results1 = extractSentences results1partial

text1basic :: String
text1basic = "my dog found a yellow ball ."
results1basic :: [Node]
results1basic = lexNodes text1basic

text1half :: String
text1half = "he ran after the blue ball when I threw it ."
results1halfpartial :: [Grammar.Node]
results1halfpartial = lexNodes text1half
results1half :: [Node]
results1half = extractSentences results1halfpartial
