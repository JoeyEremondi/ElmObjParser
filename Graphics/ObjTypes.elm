module Graphics.ObjTypes where

{-| General types used in loading of OBJ files.

@docs VertV, VertVT, VertVN, VertVTN, MaterialData, Uniforms 

-}

import Math.Vector3 (..)
import Math.Vector4 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)
import Graphics.Camera (..)

import Graphics.Camera as Camera



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
Information about how to render the surface of an object.
Eventually will support parsing of MTL files and specifying specular 
and diffuse properties of materials, bump-maps, etc.
-}
data MaterialData = OneColorMaterial Vec3 | OneTextureMaterial Texture | FullMaterial Material Texture

data ColorData = OneColor Vec3 | TexColor Texture

data ShadowData = NoShadows | SolidShadows

data ProjectionType = Perspective | Ortho

type Material = {
    baseColor : ColorData,
    diffuseColor : Maybe ColorData,
    specColor : Maybe ColorData,
    specCoeff : Maybe Float,
    
    bumpMap : Maybe Texture,
    reflectivity : Maybe Float
}

type ObjectProperties = {
    position : Vec3,
    rotation : Float,
    scaleFactor : Vec3
}

type GlobalProperties = {
     camera : Camera,
     shadow : ShadowData,
     screenDims : (Int, Int)
}

{-|
Uniform values which must be provided in order to render a model.
The model matrix defines the object's position, size and orientation in space,
while the view matrix defines the camera position, as well as the type of 3D projection
used.

-}
type Uniforms = { viewMatrix: Mat4, modelMatrix : Mat4 }