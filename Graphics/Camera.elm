module Graphics.Camera where

import Keyboard
import Mouse
import Window

import Math.Vector3 (..)
import Math.Vector3 as Vec3

import Math.Matrix4 (..)
import Math.Matrix4 as Mat4

data Inputs
    = TimeDelta Bool {x:Int, y:Int} Float
    --| Mouse (Int,Int)

type Camera = {position : Vec3, 
  whereToLook : WhereToLook, 
  zoom : Float}

data WhereToLook = AtPoint Vec3
  | InDirection Vec3
  | ByRotation (Float, Float)

eyeLevel : Float
eyeLevel = -0.5

--TODO up direction?

inputs : Signal Inputs
inputs =
  let dt = lift (\t -> t/500) (fps 60)
  in (sampleOn dt <| lift3 TimeDelta Keyboard.space Keyboard.wasd dt)


defaultCamera : Camera
defaultCamera =
    { position = vec3 0 0 10,
    whereToLook = AtPoint <| vec3 0 0 0
    , zoom = 1.0
    } 

--TODO zoom?
lookAtPoint : WhereToLook -> Vec3
lookAtPoint wtl = case wtl of
  AtPoint v -> v
  _ -> vec3 0 0 0  

makeView cam = makeLookAt cam.position (lookAtPoint cam.whereToLook) (vec3 0 1 0)
    
--direction : Camera -> Vec3
--direction cam =
--    let h = cam.horizontalAngle
--        v = cam.verticalAngle
--    in vec3 (cos h) (sin v) (sin h)  
    
step inputs cam =
    case inputs of
      TimeDelta isJumping keyIn dt ->
          {cam | position <- cam.position `add` (vec3 (toFloat keyIn.x) (toFloat keyIn.y) 0.0)}