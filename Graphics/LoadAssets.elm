module Graphics.LoadAssets where

import Http (..)

data LoadingElement = 
  ElementLoading
  | ElementLoaded
  | ElementFailed String
  
data LoadStatus = 
  InProgress Float
  | LoadComplete
  | LoadFailed [String]
  

addFailString el listSoFar = case el of
  ElementFailed s -> listSoFar ++ [s]
  _ -> listSoFar  

accumLoading el numSoFar = case el of
  ElementLoading -> numSoFar + 1
  _ -> numSoFar
  
failStrings elList = foldr addFailString [] elList
numLoading elList = foldr accumLoading 0 elList

toElement : Response a -> LoadingElement
toElement resp = case resp of
  Success _ -> ElementLoaded
  Failure _ s -> ElementFailed s
  Waiting -> ElementLoading

toLoadStatus : [LoadingElement] -> LoadStatus
toLoadStatus els = let
    numEls = length els
    fails = failStrings els
    num = numLoading els
  in if
    | not <| isEmpty fails -> LoadFailed fails
    | num > 0 -> InProgress <| (100.0 * (toFloat num)) / (toFloat numEls)    
    | otherwise -> LoadComplete
