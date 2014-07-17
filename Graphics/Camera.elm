module Graphics.Camera where

import Math.Vector3 (..)
import Math.Vector3 as Vec3

import Math.Matrix4 (..)
import Math.Matrix4 as Mat4

type Camera = {position : Vec3, 
  whereToLook : WhereToLook, 
  zoom : Float}

data WhereToLook = AtPoint Vec3
  | InDirection Vec3
  | ByRotation (Float, Float)

--Soon I hope to implement the "Up" direction as part of the Camera type
 


defaultCamera : Camera
defaultCamera =
    { position = vec3 0 0 10,
    whereToLook = AtPoint <| vec3 0 0 0
    , zoom = 1.0
    } 

lookAtPoint : WhereToLook -> Vec3
lookAtPoint wtl = case wtl of
  AtPoint v -> v
  _ -> vec3 0 0 0  

makeView cam = let
    lookMatrix = makeLookAt cam.position (lookAtPoint cam.whereToLook) (vec3 0 1 0)
    zoomMatrix = makeScale <| vec3 cam.zoom cam.zoom cam.zoom
  in mul zoomMatrix lookMatrix
    
--direction : Camera -> Vec3
--direction cam =
--    let h = cam.horizontalAngle
--        v = cam.verticalAngle
--    in vec3 (cos h) (sin v) (sin h)  
  
{-  
step inputs cam =
    case inputs of
      TimeDelta isJumping keyIn dt ->
          {cam | position <- cam.position `add` (vec3 (toFloat keyIn.x) (toFloat keyIn.y) 0.0)}
          -}