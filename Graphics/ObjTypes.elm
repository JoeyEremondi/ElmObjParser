module Graphics.ObjTypes where

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

type VertV = {position: Vec3}
type VertVT = {position : Vec3, texCoord : Vec3}
type VertVN = {position : Vec3, normal : Vec3}
type VertVTN = {position : Vec3, texCoord : Vec3, normal : Vec3}