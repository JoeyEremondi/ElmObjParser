module Graphics.ObjParser where

import String
import Array
import Http


import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjShaders (..)

import Graphics.ObjTypes (..)




type Uniforms = { viewMatrix: Mat4, modelMatrix : Mat4, normalMatrix : Mat4, inputColor: Vec3 }

data FaceVert =   FaceVertV VertV
  | FaceVertVT VertVT
  | FaceVertVN VertVN
  | FaceVertVTN VertVTN

data Model = 
  FlatColored [Triangle VertV] {color:Vec3}
  | FlatTextured [Triangle VertVT] {texture : Texture}
  | SmoothColored [Triangle VertVN] {color:Vec3}
  | SmoothTextured [Triangle VertVTN] {texture : Texture}


  


data ColorData = OneColor Vec3 | OneTexture Texture

--Helper function
triToList : Triangle a -> [a]
triToList (a,b,c) = [a,b,c]

--Given an OBJ string and options, convert it to a model
toModel : String -> ColorData -> Model
toModel objSource colorData = let
    triangles = parseObj objSource
    faceList = concat <| map triToList triangles
  in case (containsV faceList, containsVT faceList, containsVN faceList, colorData) of
    (True, _, _, OneColor col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, True, True, OneColor col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, True, _, OneTexture tex) -> FlatTextured (map (mapTriangle toVT) triangles) {texture = tex}
    (_, True, _, OneColor col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, _, True, OneColor col) -> SmoothColored (map (mapTriangle toVN) triangles) {color = col}
    (False, False, False, OneTexture tex) ->  SmoothTextured (map (mapTriangle toVTN) triangles) {texture = tex}
    (False, False, False, OneColor col) ->   SmoothColored (map (mapTriangle toVN) triangles) {color = col}
    _ -> FlatColored (map (mapTriangle toV) triangles) {color = vec3 0.5 0.5 0.5}

toEntity : Signal Model -> Signal Uniforms -> Signal Entity
toEntity sModel sUniforms = let
    mainFun model uniforms = case model of
      (SmoothColored triangles _) -> entity vertexShaderVN fragmentShaderVN triangles uniforms
      (FlatColored triangles _) -> entity vertexShaderV fragmentShaderV triangles uniforms
      (FlatTextured triangles rec) -> entity vertexShaderVT fragmentShaderVT triangles {uniforms | texture = rec.texture }
        
  in lift2 mainFun sModel sUniforms
   

--Functions for checking what data we have avaliable
--Test if we have vertices of a given information level
containsV : [FaceVert] -> Bool
containsV l = case l of
  [] -> False
  ((FaceVertV _) :: _) -> True
  (_ :: rest) -> containsV rest

containsVT : [FaceVert] -> Bool
containsVT l = case l of
  [] -> False
  ((FaceVertVT _) :: _) -> True
  (_ :: rest) -> containsV rest  

containsVN : [FaceVert] -> Bool
containsVN l = case l of
  [] -> False
  ((FaceVertVN _) :: _) -> True
  (_ :: rest) -> containsV rest

--Convert vertices to a (lower) information level
toV : FaceVert -> VertV
toV face = case face of
  FaceVertV v -> v
  FaceVertVN v -> {position = v.position}
  FaceVertVT v -> {position = v.position}
  FaceVertVTN v -> {position = v.position}

toVT : FaceVert -> VertVT
toVT face = case face of
  FaceVertVT v -> v
  FaceVertVTN v -> {position = v.position, texCoord = v.texCoord}
  
toVN : FaceVert -> VertVN
toVN face = case face of
  FaceVertVN v -> v
  FaceVertVTN v -> {position = v.position, normal = v.normal}  


toVTN f = case f of
  FaceVertVTN vtn -> vtn
  FaceVertVN vn -> {position = vn.position, normal = vn.normal, texCoord = vec3 0 0 0}

data Face = FaceV (VertV, VertV, VertV) 
  | FaceVT (VertVT, VertVT, VertVT)
  | FaceVN (VertVN, VertVN, VertVN)
  | FaceVTN (VertVTN, VertVTN, VertVTN)

--Used to avoid "Math.pow is not a function"
myPow : Float -> Int -> Float
myPow b e = if
  | e < 0 -> 1.0 / (myPow b (0-e))
  | e == 0 -> 1
  | e > 0 -> b * (myPow b (e-1))

--Check if a float is in scientific notation, then parse it accordingly
parseFloat : String -> Float
parseFloat s = case String.split "e" s of
  [fs] -> fromJust <| String.toFloat fs
  [base, power] -> let
      bf = fromJust <| String.toFloat base
      pi = fromJust <| String.toInt power
    in bf  * (myPow 10.0 pi)


--Check the first character of a line for parsing
isVertexLine= (\s -> "v" == (head <| String.words s))
isVtLine= (\s -> String.startsWith "vt" s)
isVnLine= (\s -> String.startsWith "vn" s)
isFaceLine = (\s -> String.startsWith "f" s)

lineToVert : String -> Vec3
lineToVert line = case (String.words line) of
  ["v", v1, v2, v3] -> vec3 (parseFloat v1)  (parseFloat v2) (parseFloat v3) 
  
lineToVn line = case (String.words line) of
  ["vn", v1, v2, v3] -> vec3 (parseFloat v1)  (parseFloat v2) (parseFloat v3)
  
lineToVt line = case (String.words line) of
  ["vt", v1, v2, v3] -> vec3 (parseFloat v1)  (parseFloat v2) (parseFloat v3)
  ["vt", v1, v2] -> vec3 (parseFloat v1)  (parseFloat v2) (0.0)

lineToFace : (Array.Array Vec3, Array.Array Vec3, Array.Array Vec3) -> String -> [Triangle FaceVert]
lineToFace arrs line = case (String.words line) of
  ["f", f1, f2, f3] -> [(parseFaceVert arrs f1, parseFaceVert arrs f2, parseFaceVert arrs f3)]
  ["f", f1, f2, f3, f4] -> [(parseFaceVert arrs f1, parseFaceVert arrs f2, parseFaceVert arrs f3),
    (parseFaceVert arrs f2, parseFaceVert arrs f3, parseFaceVert arrs f4)]
  --x -> Error.raise <| show x

--Eventually will look for normals and such
--Right now, just converts the string to the vertex index
parseFaceVert : (Array.Array Vec3, Array.Array Vec3, Array.Array Vec3) -> String -> FaceVert
parseFaceVert (vArr, vtArr, vnArr) str = case String.split "//" str of
  [v, n] -> FaceVertVN <| VertVN (deIndexVert vArr v) (deIndexVert vnArr n) --vertex and normal
  [s] -> case String.split "/" s of
    [v] -> FaceVertV <| VertV (deIndexVert vArr v) --only vertex
    [v,t] -> FaceVertVT <| VertVT (deIndexVert vArr v) (deIndexVert vtArr t) --vertex and tex coords
    [v,t,n] -> FaceVertVTN <| VertVTN (deIndexVert vArr v) (deIndexVert vtArr t) (deIndexVert vnArr n) --all 3.
fromJust (Just x) = x


--Given 3 indices and vertex array, get the right vertex from the array
deIndexVert vArr s = let
    i = fromJust <| String.toInt s
  in Array.getOrFail (i-1) vArr

--Parse an OBJ file into a list of triangles  
parseObj : String -> [Triangle FaceVert]
parseObj inFile = 
  let 
    lines = String.lines inFile
    
    vLines = filter isVertexLine lines
    vertices = Array.fromList <| map lineToVert vLines
    
    vtLines = filter isVtLine lines
    texCoords = Array.fromList <| map lineToVt vtLines
    
    vnLines = filter isVnLine lines
    normals = Array.fromList <| map lineToVn vnLines
    
    fLines = filter isFaceLine lines
    faces = concat <| map (lineToFace (vertices, texCoords, normals) ) fLines
    
  in faces

--Test mesh
--mesh inFile = map (\(a,b,c) -> (toVTN a, toVTN b, toVTN c)) <| parseObj inFile



