{-# OPTIONS_GHC -Wall #-}

module Parser where

import Grammar
import GrammarFilters

applyRules :: Node -> [Node]
applyRules eof@(Node EOF _ _) = [eof]
applyRules node =
  let
    -- We don't need to recursively apply the rules for our successor nodes;
    -- that already happened when they were lexed. We did that because data in
    -- Haskell is immutable, and we want to parse them only once regardless of
    -- how many parent nodes there are. Otherwise, we'll duplicate major amounts
    -- of work (doubling the work required after each time there are two
    -- ambiguous nodes).
    applyRulesFixedPoint current@(Node _ rules _) =
      let
        newNodes = concatMap (\f -> f current) $ rules
      in
        -- Now apply the Rules of all the new Nodes generated, and apply the
        -- Rules of all new Nodes generated by this new application, until we
        -- stop creating new Nodes.
        (concatMap applyRulesFixedPoint newNodes) ++ newNodes
  in
    node : applyRulesFixedPoint node

applyAllRules :: [Node] -> [Node]
applyAllRules = concatMap applyRules

extractSentences :: [Node] -> [Node]
extractSentences nodes =
  let
    sentenceNodes = filter (liftFilter isFullSentence) nodes
    extractChildSentences eof@(Node EOF _ _) = eof
    extractChildSentences (Node sentence rules rest) =
        Node sentence rules (extractSentences rest)
  in
    map extractChildSentences (if null sentenceNodes
                               then nodes
                               else sentenceNodes)
