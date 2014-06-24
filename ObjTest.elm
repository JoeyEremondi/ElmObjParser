module ObjTest where

import Graphics.ObjParser (..)
import Graphics.ObjTypes (..)

import LoadAssets as Load

import Graphics.Camera as Camera

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Http



--Based off the triangle rendering code from http://elm-lang.org/edit/examples/WebGL/Triangle.elm
  
-- Create the scene

--camera : Signal (Camera.Camera)
camera =  foldp Camera.step Camera.defaultCamera Camera.inputs

--main : Signal Element



main = let
    inResp = Http.sendGet <| constant "/capsule.obj"
    texResp = loadTexture "/capsule0.jpg"
    bumpResp = loadTexture "/Orange-bumpmap.png"
    inAsset = lift Load.toAsset inResp
    texAsset = lift Load.toAsset texResp
    bumpAsset = lift Load.toAsset bumpResp
    assets = combine [inAsset, texAsset, bumpAsset]
    loadStatSig = lift Load.toStatus assets
    

    modelSig = lift4
     (\loadStatSig inFile texFile bumpFile -> case loadStatSig of
        Load.Complete -> let
          tex = Load.fromResponseOrFail texFile
          bump = Load.fromResponseOrFail bumpFile
          material = {
            baseColor = TexColor tex,
            diffuseColor = Just (OneColor <| vec3 0.4 0.4 0.4),
            specColor = Just (OneColor <| vec3 0.1 0.1 0.1),
            specCoeff = Just (0.8),
            bumpMap = Just bump,
            reflectivity = Nothing }
          
        in  toModel (Load.fromResponseOrFail inFile) ( FullMaterial material tex )
        _ -> emptyModel
     ) loadStatSig inResp texResp bumpResp
    
  
    defaultCam = Camera.defaultCamera
    
    theCam = {defaultCam | position <- vec3 0 0 10}
  
    objProperties = lift objAtTime (foldp (+) 0 (fps 30))
                
    globProperties = lift globalsFromCam camera
  
  in lift4 render modelSig myUnis ( objProperties) ( globProperties)
  
globalsFromCam : Camera.Camera -> GlobalProperties
globalsFromCam cam = {camera = cam,
    shadow = NoShadows,
    screenDims = (1000, 1000)}
    
objAtTime t = {position = vec3 0 0 0,
                rotation = (t / 1500),
                scaleFactor = vec3 1 1 1}

  
render model unis obj glob = let
    myScene ent =  webgl (1000,1000) [ent]
    ent = toEntity model unis obj glob
  in myScene ent

myUnis = lift3 uniformsAtTime (constant (1000,1000)) camera (foldp (+) 0 (fps 30))

uniformsAtTime dims cam t  = let
    m = modelMat (t / 1500)
    v = view dims cam
  in { viewMatrix = v,  modelMatrix = m}

view _ _  = identity

modelMat : Float -> Mat4
modelMat t = let
    s = identity
    tr = identity
    r = makeRotate t (vec3 0 1 0)
  in mul tr (mul r s)
