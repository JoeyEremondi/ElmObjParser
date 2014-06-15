module Graphics.ObjShaders where

import Math.Vector3 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Graphics.ObjTypes (..)


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

const vec3 lightPos = vec3(10.0, 10.0, 10.0);
const vec3 specColor = vec3(0.02, 0.02, 0.02);

void main () {

  // all following gemetric computations are performed in the
  // camera coordinate system (aka eye coordinates)
  vec3 adjustedNormal = vec3(normalMatrix * vec4(vNorm, 0.0));
  vec3 vertPos = vcoord;
  vec3 lightDir = (lightPos - vertPos);
  vec3 reflectDir = reflect(-lightDir, adjustedNormal);
  vec3 viewMatrixDir = (-vertPos);
  
  vec3 diffuseColor = 0.3*texture2D(texture, tcoord.xy).xyz;
  vec3 ambientColor = diffuseColor;

  float lambertian = max(dot(lightDir,adjustedNormal), 0.0);
  float specular = 0.0;
  
  if(lambertian > 0.0) {
    float specAngle = max(dot(reflectDir, viewMatrixDir), 0.0);
    specular = pow(specAngle, 0.2);
       
    
  }
  gl_FragColor = vec4((lambertian*diffuseColor + specular*specColor) + ambientColor, 1.0);



  
}

|]