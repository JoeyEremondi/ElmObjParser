module Graphics.ObjTypes where

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

{-|
Vertex containing only position data
-}
type VertV = {position: Vec3}

{-|
Vertex containing spatial position, and texture coordinates to sample from
-}
type VertVT = {position : Vec3, texCoord : Vec3}

{-|
Vertex containing a spatial position and a normal vector used for lighting
-}
type VertVN = {position : Vec3, normal : Vec3}

{-|
Vertex containing position, texture coordinates and normal vector
-}
type VertVTN = {position : Vec3, texCoord : Vec3, normal : Vec3}

{-|
Information about how to render the surface of an object
-}
data MaterialData = OneColor Vec3 | OneTexture Texture

{-|
Uniform values which must be provided in order to render a model
-}
type Uniforms = { viewMatrix: Mat4, modelMatrix : Mat4, normalMatrix : Mat4 }