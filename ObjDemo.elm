import Graphics.Input (Input, input, dropDown)
import Text
import Dict
import Graphics.WebGL (loadTexture, Texture)

import LoadAssets as Load
import Http

--User picks from a list, is either
data TexChoice = SolidColor Color | TexturePath String


main : Signal Element
main = let
    elem = lift makeElems inputSig
  in elem

style : Input TexChoice
style = input <| snd <| head colorOptions

theInput = { texture = input <| SolidColor black,
    model = input <| "capsule.obj"
    }

inputSig = let
        liftInput tex mod = {
            texture = tex,
            model = mod
        }
    in liftInput <~ theInput.texture.signal ~ theInput.model.signal


makeElems inputValues = flow down [
     dropDown theInput.texture.handle colorOptions,
     dropDown theInput.model.handle modelOptions,
     plainText <| show inputValues.texture,
     plainText <| show inputValues.model
    ]
    
makeVars inputValues = {

}

--display : String -> Element
display (status, texDict, modelDict) texChoice = case status of
   Load.Complete -> let msg = "Objects loaded"
     in flow down [plainText msg,  dropDown style.handle colorOptions, plainText <| show texChoice]
   Load.InProgress f -> plainText <| "Remote assets " ++ (show <| 100*f) ++ "% loaded"
   Load.Failed errors -> plainText <| "Error loading assets: " ++ (show errors)
            

colorOptions : [(String, TexChoice)]
colorOptions = [ 
          ("orange", TexturePath "Orange-bumpmap.png")
          , ("grid", TexturePath "capsule0.jpg")

          ]
          
modelOptions : [(String, String)]
modelOptions = [ ("bunny"    , "bunny.obj")
          , ("capsule", "capsule.obj")


          ]

pair x y = (x,y)


textureNames = let
    isTex choice = case choice of
      TexturePath _ -> True
      _ -> False
    toPath (TexturePath s) = s
  in map toPath <| filter isTex <| map snd colorOptions
  
          
remoteAssets : Signal (Load.Status, Dict.Dict String Texture, Dict.Dict String String)
remoteAssets = let
    texRespSigs = map loadTexture textureNames
    texRespListSig = combine texRespSigs
    
    modelNames = map snd modelOptions
    modelRespSigs = map (\path -> Http.sendGet <| constant path ) modelNames
    modRespListSig = combine modelRespSigs
    
    makeStatus texResps modelResps = Load.toStatus <| (map Load.toAsset texResps) ++ (map Load.toAsset modelResps)
    statusSig = lift2 makeStatus texRespListSig modRespListSig
    
    makeDicts texResps modelResps status = case status of
        Load.Complete -> let
            textures = map Load.fromResponseOrFail texResps
            models = map Load.fromResponseOrFail modelResps
            texDict = Dict.fromList <| zip textureNames textures
            modelDict = Dict.fromList <| zip modelNames models
          in  (Load.Complete, texDict, modelDict)
        status -> (status, Dict.empty, Dict.empty)
        

    
    
  in lift3 makeDicts texRespListSig modRespListSig statusSig

