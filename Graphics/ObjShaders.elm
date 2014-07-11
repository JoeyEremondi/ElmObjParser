module Graphics.ObjShaders where

import Math.Vector3 (..)
import Math.Vector4 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjTypes (..)

import Graphics.Camera as Camera

import Native.Graphics.WebGL


basicFragShader = [glsl|

precision mediump float;
varying vec3 vcolor;

void main () {
    gl_FragColor = vec4(vcolor, 1.0);
}

|]



vertexShaderVN : Shader VertVN { unif |  modelMatrix:Mat4, viewMatrix:Mat4, normalMatrix:Mat4, inputColor : Vec3 } { vcolor:Vec3 }
vertexShaderVN = [glsl|

attribute vec3 position;
attribute vec3 normal;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 normalMatrix;
uniform vec3 inputColor;
varying vec3 vcolor;



const vec3 lightPos = vec3(1.0, 1.0, 1.0);
const vec3 specColor = vec3(0.2, 0.2, 0.2);

void main(){

  vec3 ambientColor = inputColor;
  vec3 diffuseColor = inputColor;
  vec4 finalPos = viewMatrix * modelMatrix * vec4(position, 1.0);
  gl_Position = finalPos;

  // all following gemetric computations are performed in the
  // camera coordinate system (aka eye coordinates)
  vec3 adjustedNormal = vec3(normalMatrix * vec4(normal, 0.0));
  vec4 vertPos4 = viewMatrix * modelMatrix * vec4(position, 1.0);
  vec3 vertPos = vec3(vertPos4) / vertPos4.w;
  vec3 lightDir = (lightPos - vertPos);
  vec3 reflectDir = reflect(-lightDir, adjustedNormal);
  vec3 viewMatrixDir = (-vertPos);

  float lambertian = max(dot(lightDir,adjustedNormal), 0.0);
  float specular = 0.0;
  
  if(lambertian > 0.0) {
    float specAngle = max(dot(reflectDir, viewMatrixDir), 0.0);
    specular = pow(specAngle, 4.0);
       
    
  }
  vcolor = vec3(lambertian*diffuseColor + specular*specColor) + ambientColor;
}


|]

fragmentShaderVN : Shader {} u { vcolor:Vec3 }
fragmentShaderVN = basicFragShader





vertexShaderV : Shader VertV { unif |  modelMatrix:Mat4, viewMatrix:Mat4, inputColor : Vec3 } { vcolor:Vec3 }
vertexShaderV = [glsl|

attribute vec3 position;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec3 inputColor;
varying vec3 vcolor;


void main(){
  gl_Position = viewMatrix * modelMatrix * vec4(position, 1.0);
  
  
  vcolor = inputColor;
}


|]

fragmentShaderV : Shader {} u { vcolor:Vec3 }
fragmentShaderV = basicFragShader

vertexShaderVT : Shader VertVT { unif |  modelMatrix:Mat4, viewMatrix:Mat4 } { vcoord : Vec3 }
vertexShaderVT = [glsl|

attribute vec3 position;
attribute vec3 texCoord;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
varying vec3 vcoord;


void main(){
  gl_Position = viewMatrix * modelMatrix * vec4(position, 1.0);
  
   vcoord = texCoord;
  
}


|]

fragmentShaderVT : Shader {} { u | texture:Texture } { vcoord:Vec3 }
fragmentShaderVT = [glsl|

precision mediump float;
uniform sampler2D texture;
varying vec3 vcoord;

void main () {
  //gl_FragColor = texture2D(texture, vcoord);
  gl_FragColor  = vec4(0,0,0,1);
}

|]


--TODO fix

vertexShaderVTN : Shader VertVTN { unif |  modelMatrix:Mat4, viewMatrix:Mat4 } { vcoord : Vec3, tcoord : Vec3, vNorm : Vec3 }
vertexShaderVTN = [glsl|

attribute vec3 position;
attribute vec3 texCoord;
attribute vec3 normal;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
varying vec3 vcoord;
varying vec3 tcoord;
varying vec3 vNorm;


void main(){
  gl_Position = viewMatrix * modelMatrix * vec4(position, 1.0);
  
   vcoord = gl_Position.xyz;
   tcoord = texCoord;
   vNorm = normal;
  
}


|]

fragmentShaderVTN : Shader {} { u | texture:Texture, normalMatrix : Mat4 } { vcoord:Vec3, tcoord : Vec3, vNorm : Vec3 }
fragmentShaderVTN = [glsl|

precision mediump float;
uniform sampler2D texture;
uniform mat4 normalMatrix;
varying vec3 vcoord;
varying vec3 tcoord;
varying vec3 vNorm;

const vec3 lightPos = vec3(100.0, 100.0, 100.0);
const vec3 specColor = vec3(0.1, 0.1, 0.1);

void main () {

  // all following gemetric computations are performed in the
  // camera coordinate system (aka eye coordinates)
  vec3 adjustedNormal = vec3(normalMatrix * vec4(vNorm, 0.0));
  vec3 vertPos = vcoord;
  vec3 lightDir = (lightPos - vertPos);
  vec3 reflectDir = reflect(-lightDir, adjustedNormal);
  vec3 viewMatrixDir = (-vertPos);
  
  vec3 diffuseColor = 0.25*texture2D(texture, tcoord.xy).xyz;
  vec3 ambientColor = 1.5*diffuseColor;

  float lambertian = max(dot(lightDir,adjustedNormal), 0.0);
  float specular = 0.0;
  
  if(lambertian > 0.0) {
    float specAngle = max(dot(reflectDir, viewMatrixDir), 0.0);
    specular = pow(specAngle, 0.2);
       
    
  }
  gl_FragColor = vec4((lambertian*diffuseColor + specular*specColor) + ambientColor, 1.0);



  
}

|]


--The large set of data that gets passed to the "full" shader
-- which supports bump-maps, texture maps, etc.
type FullShaderUniforms = {

    modelMatrix : Mat4,
    viewMatrix : Mat4,
    perspectiveMatrix : Mat4,
    normalMatrix : Mat4,
    
    pointLightPosition : Vec3,
    pointLightSpecular : Vec3,
    pointLightDiffuse : Vec3,

    globalAmbient : Vec3,

    ambientColor : Vec3,
    ambientTexture : Texture,
    useAmbientColor : Float,
    useAmbientTexture : Float,
    
    
    diffuseColor : Vec3,
    diffuseTexture : Texture,
    useDiffuseColor : Float,
    useDiffuseTexture : Float,
    
    specularColor : Vec3,
    specularTexture : Texture,
    useSpecularColor : Float,
    useSpecularTexture : Float,
    specularCoeff : Float,
    
    bumpTexture : Texture,
    useBumpTexture : Float
}

--Conventient helpers for default values
origin = vec3 0 0 0
ones = vec3 1 1 1

--Basic default values, so we have a starting point for building a record
--Important since every field needs a value, but some aren't always given
--i.e. only given diffuse color or texture, not both
defaultFullUniforms : Texture -> FullShaderUniforms
defaultFullUniforms tex = {
    modelMatrix = identity,
    viewMatrix = identity,
    perspectiveMatrix = identity,
    normalMatrix = identity,
    
    pointLightPosition = origin,
    pointLightSpecular = origin,
    pointLightDiffuse = origin,
    globalAmbient = ones,

    
    ambientColor = origin,
    ambientTexture = tex,
    useAmbientColor = 0.0,
    useAmbientTexture = 0.0,
    
    diffuseColor = origin,
    diffuseTexture = tex,
    useDiffuseColor = 0.0,
    useDiffuseTexture = 0.0,
    
    specularColor = origin,
    specularTexture = tex,
    useSpecularColor = 0.0,
    useSpecularTexture = 0.0,
    
    specularCoeff = 0.0,
    
    bumpTexture  = tex,
    useBumpTexture  = 0.0 }

--Given screen dimensions, make the appropriate perspective matrix
perspectiveForDims (w,h) = (makePerspective 45 (toFloat w / toFloat h) 0.01 100)    
    
--Given a default texture, material properties, and high level obj/global properties,
--Convert these values into the form read by the shader
makeUniforms : Texture -> Material -> ObjectProperties -> GlobalProperties -> FullShaderUniforms
makeUniforms tex matProps objProps globalProps = let
    uni1 = defaultFullUniforms tex
    uni2 = case matProps.baseColor of
        OneColor c -> {uni1 | ambientColor <- c, useAmbientColor <- 1}
        TexColor t -> {uni1 | ambientTexture <- t, useAmbientTexture <- 1}
    uni3 = case (matProps.specColor, matProps.specCoeff) of
        (Just (OneColor c), Just coeff) -> {uni2 | specularColor <- c, useSpecularColor <- 1, specularCoeff <- coeff}
        (Just (TexColor t), Just coeff) -> {uni2 | specularTexture <- t, useSpecularTexture <- 1, specularCoeff <- coeff}
        _ -> {uni2 | useSpecularColor <- 0}
    uni4 = case matProps.diffuseColor of
        Just (OneColor c) -> {uni3 | diffuseColor <- c, useDiffuseColor <- 1}
        Just (TexColor t) -> {uni3 | diffuseTexture <- t, useDiffuseTexture <- 1}
        Nothing -> uni3
        
    u5 = case matProps.bumpMap of
      Nothing -> uni4
      Just t -> {uni4 | bumpTexture <- t, useBumpTexture <- 1.0 }
      
    modelMatrix = mul (makeTranslate objProps.position) <| mul (makeScale objProps.scaleFactor) (makeRotate objProps.rotation <| vec3 0 1 0)
    viewMatrix =  Camera.makeView globalProps.camera
    perspectiveMatrix = perspectiveForDims globalProps.screenDims
    normalMatrix = let
            mv = mul viewMatrix modelMatrix 
        in transpose <| inverseOrthonormal mv 
    
    u6 = {u5 | modelMatrix <- modelMatrix, viewMatrix <- viewMatrix, perspectiveMatrix <- perspectiveMatrix, normalMatrix <- normalMatrix }
    
    --Set global lighting properties
    u7 = {u6 | globalAmbient = globalProps.ambientLight}
    u8 = case globalProps.mainLight of
        PointLight light -> {u7 | pointLightPosition <- light.pos, pointLightSpecular <- light.specular, pointLightDiffuse <- light.diffuse}
        --TODO sunlight
        
    uFinal = u8
  in uFinal
    
--Version of the shader supporting textures for amb, spec and diff, as well as bump maps
--Allows for one light    
fullVertexShader : Shader VertVTN FullShaderUniforms { vcoord : Vec3, tcoord : Vec3, vNorm : Vec3, lightVec : Vec3 }
fullVertexShader = [glsl|

precision lowp float;

attribute vec3 position;
attribute vec3 texCoord;
attribute vec3 normal;

uniform vec3 pointLightPosition;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 perspectiveMatrix;
uniform mat4 normalMatrix;

varying vec3 vcoord;
varying vec3 tcoord;
varying vec3 vNorm;
varying vec3 lightVec;



//Based off http://www.cs.unm.edu/~angel/BOOK/INTERACTIVE_COMPUTER_GRAPHICS/SIXTH_EDITION/CODE/CHAPTER05/WINDOWS_VERSIONS/vshader56.glsl
void main(){
    gl_Position = perspectiveMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);    
  
   vcoord = (viewMatrix * modelMatrix * vec4(position, 1.0)).xyz;
   tcoord = texCoord;
   vNorm = (normalMatrix * vec4(normal, 1.0)).xyz;
   if (1.0 == 0.0)
   {
	lightVec = pointLightPosition.xyz;
   }
   else
   {
     lightVec = (pointLightPosition.xyz - vcoord);
   }
   //lightVec =  (1.0-pointLightPosition.w) * pointLightPosition.xyz + (pointLightPosition.w)*(pointLightPosition.xyz - vcoord);
 
 
}


|]


fullFragmentShader : Shader {} FullShaderUniforms { vcoord:Vec3, tcoord : Vec3, vNorm : Vec3, lightVec : Vec3 }
fullFragmentShader = [glsl|


precision lowp float;
uniform mat4 normalMatrix;

uniform vec3 pointLightPosition;
uniform vec3 pointLightDiffuse;
uniform vec3 pointLightSpecular;


uniform vec3 globalAmbient;

uniform vec3 ambientColor;
uniform sampler2D ambientTexture;
uniform float useAmbientColor;
uniform float useAmbientTexture;

uniform vec3 diffuseColor;
uniform sampler2D diffuseTexture;
uniform float useDiffuseColor;
uniform float useDiffuseTexture;

uniform vec3 specularColor;
uniform sampler2D specularTexture;
uniform float useSpecularColor;
uniform float useSpecularTexture;

uniform sampler2D bumpTexture;
uniform float useBumpTexture;

uniform float specularCoeff;
varying vec3 vcoord;
varying vec3 tcoord;
varying vec3 vNorm;
varying vec3 lightVec;


void main () {

  // all following gemetric computations are performed in the
  // camera coordinate system (aka eye coordinates)
  //TODO normalize?
  vec3 lightDirection = normalize(lightVec);
  vec3 normal = normalize(vNorm) + (1.0*useBumpTexture)*(texture2D(bumpTexture, tcoord.xy)).xyz;
  vec3 vertPos = vcoord;
  vec3 reflectDir = reflect(-lightDirection, normal);
  vec3 viewMatrixDir = (-vertPos);
  
  vec3 materialBase = useAmbientColor*ambientColor + useAmbientTexture*(texture2D(ambientTexture, tcoord.xy).xyz);
  
  vec3 materialDiffuse = useDiffuseColor * diffuseColor + useDiffuseTexture*(texture2D(diffuseTexture, tcoord.xy).xyz);
  
  vec3 materialSpecular = useSpecularColor*specularColor + useSpecularTexture*(texture2D(specularTexture, tcoord.xy).xyz);
  
  vec3 base = globalAmbient * materialBase;
  vec3 diff = pointLightDiffuse * materialDiffuse;
  vec3 spec = pointLightSpecular * materialSpecular;
  

  float lambertian = max(dot(lightDirection,vNorm), 0.0);
  float specular = 0.0;
  
  if(lambertian > 0.0) {
    float specAngle = max(dot(reflectDir, viewMatrixDir), 0.0);
    specular = pow(specAngle, specularCoeff);
       
    
  }
  gl_FragColor = vec4((lambertian*diff + specular*spec) + base, 1.0);



  
}

|]

--Simply here to force shader typechecking
testEntity = entity  fullVertexShader fullFragmentShader []