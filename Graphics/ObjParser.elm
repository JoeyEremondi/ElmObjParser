module Graphics.ObjParser where

import String
import Array
import Http


import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjParserInternal as Internal

import Graphics.ObjTypes (..)


type Model = Internal.Model

--Given an OBJ string and options, convert it to a model
toModel : String -> MaterialData -> Model
toModel = Internal.toModel

toEntity : Model -> Uniforms -> Entity
toEntity = Internal.toEntity

emptyModel = Internal.EmptyModel

   



