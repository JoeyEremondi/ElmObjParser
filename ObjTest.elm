module ObjTest where

import Keyboard
import Mouse
import Window

import Graphics.ObjParser (..)
import Graphics.ObjTypes (..)

import LoadAssets as Load

import Graphics.Camera as Camera

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Http


--Different inputs which cause changes to the Camera position
data CameraInputs
    = TimeDelta Bool {x:Int, y:Int} Float
    --| Mouse (Int,Int)
    
--Create the camera input signal from input signals
inputs : Signal CameraInputs
inputs =
  let dt = lift (\t -> t/500) (fps 60)
  in (sampleOn dt <| lift3 TimeDelta Keyboard.space Keyboard.wasd dt)

--Given some user input, movie the camera based on them
--Intended for use with foldp
stepCam inputs cam =
    case inputs of
      TimeDelta isJumping keyIn dt ->
          {cam | position <- cam.position `add` (vec3 (toFloat keyIn.x) (toFloat keyIn.y) 0.0)}


--Signal representing the camera's position over time
camera : Signal (Camera.Camera)
camera =  foldp stepCam Camera.defaultCamera inputs


{-
Our main function. This does a lot of things, and the way they do them is fairly important.
We get the OBJ and Texture files using HTTP, which gives them wrapped in a Response.
We use LoadAsset to lift them into an asset type, and combine them into one loadStatus.
We lift this into a rendering function.
If the load is complete, then we know it's safe to extract them all from their Response forms.

If the load isn't complete, we just render nothing.

The modelSig function for the complete case takes the object file and parses it into a model,
after we give it our material properties.
It's important to get the Model  as its own a signal, so that we don't end up parsing
the OBJ file every clock tick.

Once we have the model signal, we get our object properties (just rotation based on time)
and our global properties (basically just camera location and some defaults).
We lift these as arguments to the render function, which produces an Element
-}
main : Signal Element
main = let
    inResp = Http.sendGet <| constant "capsule.obj"
    texResp = loadTexture "capsule0.jpg"
    bumpResp = loadTexture "Orange-bumpmap.png"
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
  
--Given a camera, create global settings with all default values except the camera
globalsFromCam : Camera.Camera -> GlobalProperties
globalsFromCam cam = {camera = cam,
    shadow = NoShadows,
    screenDims = (1000, 1000),
    ambientLight = vec3 0.3 0.3 0.3,
    mainLight = 
        PointLight {pos = vec3 1 10 10,
                    specular = vec3 0.1 0.1 0.1,
                    diffuse = vec3 0.1 0.1 0.1}}
  
--Compute the rotation of our main object at a given time  
objAtTime t = {position = vec3 0 0 0,
                rotation = (t / 1500),
                scaleFactor = vec3 1 1 1}

--This function just combines toEntity, which converts Models to a WebGL Entity,
--and the webgl function, which converts entities to HTML elements
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


  