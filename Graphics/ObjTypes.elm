module Graphics.ObjTypes where

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

type VertV = {position: Vec3}
type VertVT = {position : Vec3, texCoord : Vec3}
type VertVN = {position : Vec3, normal : Vec3}
type VertVTN = {position : Vec3, texCoord : Vec3, normal : Vec3}

data MaterialData = OneColor Vec3 | OneTexture Texture

type Uniforms = { viewMatrix: Mat4, modelMatrix : Mat4, normalMatrix : Mat4, inputColor: Vec3 }