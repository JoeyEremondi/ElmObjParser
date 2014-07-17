module Graphics.Camera where

{-| an abstract library for moving a camera in 3D space

@docs Camera, WhereToLook, defaultCamera, makeView

-}

import Math.Vector3 (..)
import Math.Vector3 as Vec3

import Math.Matrix4 (..)
import Math.Matrix4 as Mat4


type Camera = {position : Vec3, 
  whereToLook : WhereToLook, 
  zoom : Float}

{-|
  Data type representing different ways of expressing where a camera is looking.
  * AtPoint: point the camera towards a given point in 3D space. Causes problems if pointing at the camera's position.
  * InDirection: Look in a given direction (x,y and z) relative to the camera's current position.
  * ByRotation: Starting from looking in the negative z direction, rotate the camera the given number of radians
    around the XY axis, then the given number of radians upward from the current rotation.
  
-}
data WhereToLook = AtPoint Vec3
  | InDirection Vec3
  | ByRotation (Float, Float)

--Soon I hope to implement the "Up" direction as part of the Camera type
 
{-|
A default camera: starts at (0,0,10), looking at the origin, with a zoom of 1.0 (i.e. no zoom)
-}
defaultCamera : Camera
defaultCamera =
    { position = vec3 0 0 10,
    whereToLook = AtPoint <| vec3 0 0 0
    , zoom = 1.0
    } 

--Helper method to convert whereToLook to a vector to be used by makeLookAt
--Intended for use within libraries, not for general use
lookAtPoint : WhereToLook -> Vec3
lookAtPoint wtl = case wtl of
  AtPoint v -> v
  _ -> vec3 0 0 0  

{-|
Given a camera, convert it into a View matrix.
Intended primarily for use within libraries.
-}
makeView : Camera -> Mat4
makeView cam = let
    lookMatrix = makeLookAt cam.position (lookAtPoint cam.whereToLook) (vec3 0 1 0)
    zoomMatrix = makeScale <| vec3 cam.zoom cam.zoom cam.zoom
  in mul zoomMatrix lookMatrix
