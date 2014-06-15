module Graphics.ObjTest where

import Graphics.ObjParser (..)

import Graphics.LoadAssets as Load

import Graphics.Camera as Camera

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Http

fromResponse r = case r of 
  Http.Success s -> s


--Based off the triangle rendering code from http://elm-lang.org/edit/examples/WebGL/Triangle.elm
  
-- Create the scene


camera =  foldp Camera.step Camera.defaultCamera Camera.inputs

--main : Signal Element

main = let
    inResp = Http.sendGet <| constant "/capsule.obj"
    texResp = loadTexture "/capsule0.jpg"
    inAsset = lift Load.toElement inResp
    texAsset = lift Load.toElement inResp
    assets = combine [inAsset, texAsset]
    loadStatSig = lift Load.toLoadStatus assets
    
    modelSig = lift2 
     (\ir tr -> case (ir, tr) of
       (Http.Success inFile, Http.Success tex) -> toModel inFile ( OneTexture tex)
       _ -> EmptyModel
     ) inResp texResp
    
    mainFunc loadStatus model unis = case loadStatus of
      Load.InProgress x -> asText x
      Load.LoadFailed sList -> plainText "Failure"
      Load.LoadComplete -> render model unis
  in lift3 mainFunc loadStatSig  modelSig myUnis

render model unis = let
    myScene ent =  webgl (1000,1000) [ent]
    ent = toEntity model unis
  in myScene ent

myUnis = lift3 uniformsAtTime (constant (1000,1000)) camera (foldp (+) 0 (fps 30))

uniformsAtTime dims cam t  = let
    m = modelMat (t / 1500)
    v = view dims cam
  in { viewMatrix = v, normalMatrix = normal (mul v m), modelMatrix = m, inputColor = vec3 0.5 0.1 0.1 }

--Adapted from firstPerson example
view : (Int,Int) -> Camera.Camera -> Mat4  
view (w,h) cam = 
    mul (makePerspective 45 (toFloat w / toFloat h) 0.01 100)
        (makeLookAt cam.position (cam.position `add` Camera.direction cam) j)  

modelMat : Float -> Mat4
modelMat t = let
    s = identity
    tr = identity
    r = makeRotate t (vec3 0 1 0)
  in mul tr (mul r s)

normal v = transpose <| inverseOrthonormal v 
