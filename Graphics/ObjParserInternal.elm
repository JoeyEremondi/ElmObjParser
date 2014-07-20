module Graphics.ObjParserInternal where

import String
import Array
import Http


import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjShaders (..)

import Graphics.ObjTypes (..)

import Graphics.Camera as Camera









 --Normal matrix calculations for a given uniform
normal unis = let
     mv = mul unis.viewMatrix unis.modelMatrix 
  in transpose <| inverseOrthonormal unis.modelMatrix  




--Helper function
triToList : Triangle a -> [a]
triToList (a,b,c) = [a,b,c]

--Given an OBJ string and options, convert it to a model
toModel : String -> MaterialData -> Model
toModel objSource colorData = let
    triangles = parseObj objSource
    faceList = concat <| map triToList triangles
  in case (containsV faceList, containsVT faceList, containsVN faceList, colorData) of
    (True, _, _, OneColorMaterial col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, True, True, OneColorMaterial col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, True, _, OneTextureMaterial tex) -> FlatTextured (map (mapTriangle toVT) triangles) {texture = tex}
    (_, True, _, OneColorMaterial col) -> FlatColored (map (mapTriangle toV) triangles) {color = col}
    (_, _, True, OneColorMaterial col) -> SmoothColored (map (mapTriangle toVN) triangles) {color = col}
    (False, False, False, OneTextureMaterial tex) ->  SmoothTextured (map (mapTriangle toVTN) triangles) {texture = tex}
    (False, False, False, OneColorMaterial col) ->   SmoothColored (map (mapTriangle toVN) triangles) {color = col}
    (False, False, False, FullMaterial mat tex) -> MaterialModel (map (mapTriangle toVTN) triangles) mat tex
    _ -> FlatColored (map (mapTriangle toV) triangles) {color = vec3 0.5 0.5 0.5}

toEntity : Model -> ObjectProperties -> GlobalProperties -> Entity
toEntity model  objProps globalProps = let
    modelMatrix = mul (makeTranslate objProps.position) <| mul (makeScale objProps.scaleFactor) (makeRotate objProps.rotation <| vec3 0 1 0)
    viewMatrix =  Camera.makeView globalProps.camera
    perspectiveMatrix = perspectiveForDims globalProps.screenDims
    normalMatrix = let
            mv = mul viewMatrix modelMatrix 
        in transpose <| inverseOrthonormal mv 
    uniforms = {modelMatrix = modelMatrix, viewMatrix = viewMatrix, normalMatrix = normalMatrix}
  in case model of
      (SmoothColored triangles rec) -> entity vertexShaderVN fragmentShaderVN triangles {uniforms | inputColor = rec.color }
      (FlatColored triangles rec) -> entity vertexShaderV fragmentShaderV triangles {uniforms | inputColor = rec.color}
      (FlatTextured triangles rec) -> entity vertexShaderVT fragmentShaderVT triangles {uniforms | texture = rec.texture }
      (SmoothTextured triangles rec) -> entity vertexShaderVTN fragmentShaderVTN triangles {uniforms | texture = rec.texture } --TODO fix
      (MaterialModel triangles mat tex) -> let
          fullUnis = makeUniforms tex mat objProps globalProps
        in entity fullVertexShader fullFragmentShader triangles fullUnis --TODO not default
      EmptyModel -> entity vertexShaderV fragmentShaderVN [] {uniforms | inputColor = vec3 0.0 0.0 0.0}

   

--Functions for checking what data we have avaliable
--Test if we have vertices of a given information level

isV vert = case vert of
  FaceVertV _ -> True
  _ -> False
  
containsV l = any isV l
  
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

--Given models and their properties, generate the WebGL scene which can be placed on a page
render : [(Model, ObjectProperties)] -> GlobalProperties -> Element
render modList globalProps = let
    entities = map (\(mod, objProps) -> toEntity mod objProps globalProps) modList
  in webgl globalProperties.screenDims modList
