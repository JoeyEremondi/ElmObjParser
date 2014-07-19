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

{-|
Data type for the coloring of a material.
A material either has a solid color, or samples its color from some texture
-}
data ColorData = OneColor Vec3 | TexColor Texture

{-|
Specifies what kind of shadow to render in a scene.
Currently ignored.
-}
data ShadowData = NoShadows | SolidShadows

{-|
Specifies what type of projection should be used to convert the 3d scene into a 2d image.
Perspective is the usual choice for 3d scenes.
-}
--TODO support ortho
data ProjectionType = Perspective | Ortho

{-|
Specify information about a light source.
A light source can be at a particular point in space,
or extremely far away with parallel rays (such as a sun).
-}
data LightSource = 
    PointLight {pos:Vec3, specular:Vec3, diffuse:Vec3}
  | SunLight {direction:Vec3, specular:Vec3, diffuse:Vec3}

{-|
The material properties of an object, specifying its color properties,
and bumpiness.
Reflectivity is currently ignored.
For performance reasons, these values should be pre-computed, not altered every frame.
-}
type Material = {
    baseColor : ColorData,
    diffuseColor : Maybe ColorData,
    specColor : Maybe ColorData,
    specCoeff : Maybe Float,
    
    bumpMap : Maybe Texture,
    reflectivity : Maybe Float
}

{-| 
The result of loading a a model from an OBJ file
-}
type Model = InternalModel

{-|
A type specifying properties of an object to be rendered.
These values could be altered every frame using signals,
allowing for animation.
-}
type ObjectProperties = {
    position : Vec3,
    rotation : Float,
    scaleFactor : Vec3
}

{-|
The properties of the environment in which a scene is rendered, applied to all objects
It is generally reccomended to have some ambient light, so that the scene is visible.
Multiple light sources should be supported eventually, but are not supported yet.
-}
type GlobalProperties = {
     camera : Camera,
     shadow : ShadowData,
     screenDims : (Int, Int),
     ambientLight : Vec3,
     mainLight : LightSource
}


data FaceVert =   FaceVertV VertV
  | FaceVertVT VertVT
  | FaceVertVN VertVN
  | FaceVertVTN VertVTN

--TODO empty model a bad idea?
data InternalModel = 
  FlatColored [Triangle VertV] {color:Vec3}
  | FlatTextured [Triangle VertVT] {texture : Texture}
  | SmoothColored [Triangle VertVN] {color:Vec3}
  | SmoothTextured [Triangle VertVTN] {texture : Texture}
  | MaterialModel [Triangle VertVTN] Material Texture
  | EmptyModel
