module Graphics.Camera where

import Keyboard
import Mouse
import Window

import Math.Vector3 (..)
import Math.Matrix4 (..)

data Inputs
    = TimeDelta Bool {x:Int, y:Int} Float
    --| Mouse (Int,Int)

type Camera = {position : Vec3, horizontalAngle : Float, verticalAngle : Float}

eyeLevel : Float
eyeLevel = -0.5

inputs : Signal Inputs
inputs =
  let dt = lift (\t -> t/500) (fps 60)
  in (sampleOn dt <| lift3 TimeDelta Keyboard.space Keyboard.wasd dt)


defaultCamera : Camera
defaultCamera =
    { position = vec3 0 eyeLevel -10
    , horizontalAngle = degrees 90
    , verticalAngle = 0
    }  
  
direction : Camera -> Vec3
direction cam =
    let h = cam.horizontalAngle
        v = cam.verticalAngle
    in vec3 (cos h) (sin v) (sin h)  
    
step inputs cam =
    case inputs of
      TimeDelta isJumping keyIn dt ->
          {cam | position <- cam.position `add` (vec3 (toFloat keyIn.x) (toFloat keyIn.y) 0.0)}