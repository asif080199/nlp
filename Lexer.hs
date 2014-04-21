{-# OPTIONS_GHC -Wall #-}

module Lexer where

import qualified Data.Set

import Grammar
import LexerHelpers
import Nouns
import qualified Parser
import Rules

lexNodes :: String -> [Node]
lexNodes input =
  let
    -- TODO: get a smarter way of splitting things up
    text = words input
    end = Node EOF [] [end]
    toNodes [] = [end]
    toNodes (word : rest) =
        Parser.applyAllRules $ wordToNodes word (toNodes rest)
  in
    toNodes text

wordToNodes :: String -> [Node] -> [Node]
wordToNodes "." next = [Node Period [] next]
wordToNodes word next =
  let
    result = concatMap (\f -> f word next) makePartsOfSpeech
  in
    if length result == 0 then error ("unknown word: " ++ word) else result

makePartsOfSpeech :: [String -> [Node] -> [Node]]
makePartsOfSpeech = [ makeNoun
                    , makeArticle
                    , makeIntVerb
                    , makeTransVerb
                    , makeAdjective
                    , makePreposition
                    , makeMisc]

-- Yes, I know that many of these are possessive adjectives and not articles.
-- However, they act like articles, so that's what I'm going to call it here. In
-- particular, these are words that could be substituted for the word "the" in
-- the phrase "the big yellow house" but could not be substituted for "big" or
-- "yellow."
articles :: Data.Set.Set String
articles = Data.Set.fromList ["a", "another", "her", "his", "my", "the",
    "their"]
makeArticle :: String -> [Node] -> [Node]
makeArticle = makeNode articles Article articleRules

normalIntransitiveVerbs :: Data.Set.Set String
normalIntransitiveVerbs = Data.Set.fromList ["ran", "run"]

normalTransitiveVerbs :: Data.Set.Set String
normalTransitiveVerbs = Data.Set.fromList ["chew", "chewed", "eat", "found",
    "help", "like", "love", "play", "played", "threw", "was"]

adjectives :: Data.Set.Set String
adjectives = Data.Set.fromList ["big", "blue", "hungry", "red", "yellow"]
makeAdjective :: String -> [Node] -> [Node]
makeAdjective = makeNode adjectives Adjective adjectiveRules

prepositions :: Data.Set.Set String
prepositions = Data.Set.fromList ["after", "with"]
-- TODO: refactor this, maybe?.
permissivePreposition :: PrepositionAttributes
permissivePreposition = PrepositionAttributes True True True True
makePreposition :: String -> [Node] -> [Node]
-- "When" should always be followed by a sentence when used as a prepositional
-- phrase.
makePreposition "when" next =
    [Node (Preposition "when" permissivePreposition{canContainNoun = False})
     prepositionRules next]
makePreposition "of" next =
    [Node (Preposition "of" permissivePreposition{canContainSentence = False})
     prepositionRules next]
makePreposition "in" next =
    [Node (Preposition "in" permissivePreposition{canContainSentence = False})
     prepositionRules next]
-- "To" might be an infinitive.
makePreposition "to" next =
    [Node (Preposition "to" permissivePreposition)
     (infinitiveRule : prepositionRules) next]
makePreposition word next =
    makeNode prepositions (flip Preposition permissivePreposition)
        prepositionRules word next

addRule :: Node -> Rule -> Node
addRule (Node grammar rules next) newRule = Node grammar (newRule : rules) next

makeNoun :: String -> [Node] -> [Node]
makeNoun word next =
    concatMap (\(set, plural) -> makeNounCase set plural word next)
        [(normalNouns, "s"), (pluralEsNouns, "es")]

sameConjugation :: [VerbAttributes]
sameConjugation = [ VerbAttributes First False
                  , VerbAttributes Second False
                  , VerbAttributes Other False
                  , VerbAttributes First True
                  , VerbAttributes Second True
                  , VerbAttributes Third True]

makeIntVerb :: String -> [Node] -> [Node]
makeIntVerb word next =
    if Data.Set.member word normalIntransitiveVerbs
    then map (\a -> Node (Verb word a) intVerbRules next) sameConjugation
    -- TODO: fix this for verbs that end in 's'.
    else
    if last word == 's' && Data.Set.member (init word) normalIntransitiveVerbs
    then [Node (Verb word (VerbAttributes Third False)) intVerbRules next]
    else []

-- TODO: Can you think of a verb that *requires* a direct object?
makeTransVerb :: String -> [Node] -> [Node]
makeTransVerb word next =
  let
    verbRules = intVerbRules ++ transVerbRules
  in
    if Data.Set.member word normalTransitiveVerbs
    then map (\a -> Node (Verb word a) verbRules next) sameConjugation
    -- TODO: fix this for verbs that end in 's'.
    else
    if last word == 's' && Data.Set.member (init word) normalTransitiveVerbs
    then [Node (Verb word (VerbAttributes Third False)) verbRules next]
    else []

makeMisc :: String -> [Node] -> [Node]
makeMisc "I" next = [Node (Noun "I" (NounAttributes { canBeSubject = True
                                                    , canBeObject = False
                                                    , isPluralN = False
                                                    , personN = First}))
                          nounRules next]
makeMisc "he" next = [Node (Noun "he" (NounAttributes { canBeSubject = True
                                                      , canBeObject = False
                                                      , isPluralN = False
                                                      , personN = Third}))
                           nounRules next]
makeMisc "me" next = [Node (Noun "me" (NounAttributes { canBeSubject = False
                                                      , canBeObject = True
                                                      , isPluralN = False
                                                      , personN = First}))
                           nounRules next]
makeMisc "it" next = [Node (Noun "it" (NounAttributes { canBeSubject = True
                                                      , canBeObject = True
                                                      , isPluralN = False
                                                      , personN = Third}))
                           nounRules next]
makeMisc "and" next = [Node (Conjunction "and") conjunctionRules next]
makeMisc _ _ = []
