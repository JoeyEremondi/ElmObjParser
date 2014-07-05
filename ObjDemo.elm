import Graphics.Input (Input, input, dropDown)
import Text
import Dict
import Graphics.WebGL (loadTexture, Texture)

import LoadAssets as Load
import Http


main : Signal Element
main = lift display style.signal

style : Input String
style = input <| snd <| head colorOptions

display : String -> Element
display s =
  let msg = toText "Choose a style for the following text: " in
   flow down [  dropDown style.handle colorOptions, plainText s]
            

colorOptions : [(String, String)]
colorOptions = [ ("black"    , "black.jpg")
          , ("orange", "orange.jpg")
          , ("grid", "grid.jpg")
          , ("stripes", "stripes.jpg")
          , ("camo", "camo.jpg")
          , ("brick", "brick.jpg")

          ]
          
modelOptions : [(String, String)]
modelOptions = [ ("bunny"    , "bunny.obj")
          , ("dragon", "dragon.obj")
          , ("capsule", "capsule.obj")


          ]

pair x y = (x,y)          
          
--textureDict : Signal (Load.Status, Dict.Dict String Texture)
textureDict = let
    textureNames = map snd colorOptions
    texRespSigs = map loadTexture textureNames
    texRespListSig = combine texRespSigs
    
    modelNames = map snd modelOptions
    modelRespSigs = map (\path -> Http.sendGet <| constant path ) modelNames
    modRespListSig = combine modelRespSigs
    
    makeStatus texResps modelResps = Load.toStatus <| (map Load.toAsset texResps) ++ (map Load.toAsset modelResps)
    statusSig = lift2 makeStatus texRespListSig modRespListSig

    
    
  in lift2 pair (constant Load.Complete) (constant Dict.empty)

