module LoadAssets where

{-| A library providing some utilites for loading a large number of resources
of different types from a remote origin using HTTP,
and querying how many of them are loaded.

#Single assets
@docs Asset, toAsset, 

#Asset groups loaded together
@docs Status, toStatus

#Unsafely extracting from Http.request
@docs fromResponseOrFail

-}

import Http

{-|
Generic type for any asset which is loaded remotely.
|-}
data Asset = 
  AssetLoading
  | AssetLoaded
  | AssetFailed (Int, String)
  
{-|
Convert a response of any type to an `Asset`
|-}
toAsset : Http.Response a -> Asset
toAsset resp = case resp of
  Http.Success _ -> AssetLoaded
  Http.Failure i s -> AssetFailed (i,s)
  Http.Waiting -> AssetLoading

{-|
Structure holding the load status of a number of assets
|-}  
data Status = 
  InProgress Float
  | Complete
  | Failed [(Int, String)]
  

addFailString el listSoFar = case el of
  AssetFailed s -> listSoFar ++ [s]
  _ -> listSoFar  

accumLoading el numSoFar = case el of
  AssetLoading -> numSoFar + 1
  _ -> numSoFar
  
failStrings elList = foldr addFailString [] elList
numLoading elList = foldr accumLoading 0 elList

{-|
Given a number of assets, generate their load status us a group.
Useful for progress bars and loading screens.
|-}
toStatus : [Asset] -> Status
toStatus els = let
    numEls = length els
    fails = failStrings els
    num = numLoading els
  in if
    | not <| isEmpty fails -> Failed fails
    | num > 0 -> InProgress <| (100.0 * (toFloat num)) / (toFloat numEls)    
    | otherwise -> Complete

{-|
Get a value from an HTTP request.
This is only safe to call if the asset being retrieved
is in a load group that has evaluated to `Success`
|-}
fromResponseOrFail : Http.Response a -> a
fromResponseOrFail r = case r of 
  Http.Success s -> s