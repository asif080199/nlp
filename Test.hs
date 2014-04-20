{-# OPTIONS_GHC -Wall #-}

module Test where

import qualified Grammar
import qualified Lexer
import qualified Parser

-- I've gotten some example text appropriate for first grade reading levels from
-- http://www.superteacherworksheets.com/1st-comprehension.html

-- Text taken from the first grade reading comprehension worksheet at
-- http://www.superteacherworksheets.com/reading-comp/1st-ball-for-my-dog_TZZMD.pdf
text1 :: String
text1 = "my dog found a ball . it was a yellow ball . my dog loves to chew . he chewed the yellow ball . my dog found another ball . it was a red ball . my dog loves to play . he played with the red ball . my dog found another ball . it was a blue ball . my dog loves to run . he ran after the blue ball when I threw it ."
results1partial :: [Grammar.Node]
results1partial = Lexer.lexNodes text1
results1 :: [Grammar.Node]
results1 = Parser.extractSentences results1partial

text1half :: String
text1half = "he ran after the blue ball when I threw it ."
results1halfpartial :: [Grammar.Node]
results1halfpartial = Lexer.lexNodes text1half
results1half :: [Grammar.Node]
results1half = Parser.extractSentences results1halfpartial
