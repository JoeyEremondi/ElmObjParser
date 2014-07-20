module Graphics.ObjParser where

{-| General types used in loading of OBJ files.

@docs  toModel, render, emptyModel

-}

import String
import Array
import Http


import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjParserInternal as Internal

import Graphics.ObjTypes (..)



{-|
 Given an the string of an OBJ file and material options, convert it to a model
 -}
toModel : String -> MaterialData -> Model
toModel = Internal.toModel

{-|
 Given an model and values for uniform variables (i.e. model transformation matrix, camera view matrix, lighting information),
 create an entity which can be rendered using `webgl`
 -}
 --TODO update
toEntity : Model -> ObjectProperties -> GlobalProperties -> Entity
toEntity = Internal.toEntity

{-|
A default model with no triangles
-}
emptyModel : Model
emptyModel = EmptyModel

{-|
Given a list of models and their properties, and the global properties for a scene,
render it into the actual WebGL element which can be placed in an HTML page.
-}   
render : [(Model, ObjectProperties)] -> GlobalProperties -> Element
render = Internal.render


