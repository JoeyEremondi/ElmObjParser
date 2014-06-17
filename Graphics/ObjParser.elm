module Graphics.ObjParser where

import String
import Array
import Http


import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjParserInternal as Internal

import Graphics.ObjTypes (..)

{-| 
The result of loading a a model from an OBJ file
-}
type Model = Internal.Model

{-|
 Given an the string of an OBJ file and material options, convert it to a model
 -}
toModel : String -> MaterialData -> Model
toModel = Internal.toModel

{-|
 Given an model and values for uniform variables (i.e. model transformation matrix, camera view matrix, lighting information),
 create an entity which can be rendered using `webgl`
 -}
toEntity : Model -> Uniforms -> Entity
toEntity = Internal.toEntity

{-|
A "default" model with no triangles
-}
emptyModel = Internal.EmptyModel

   



