
precision highp float;

uniform sampler2D uFirstTexture;
uniform sampler2D uSecondTexture;
uniform sampler2D uMaskTexture;
uniform float uProgress;
uniform float uCropV;
uniform float uCropH;

in vec2 vUv;
out vec4 outColor;

#include './noise.glsl';

// Random number
float rand(vec2 co){
  return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {

  vec4 final = vec4(0.);
  
  //---- Update UV (parallax effect)
  vec2 adjustedUV = vec2(vUv.x + uCropH, vUv.y + uCropV);
  adjustedUV.x -= (uProgress * uCropH * 2.);
  adjustedUV.y -= (uProgress * uCropV * 2.);

  // Clamp to prevent out-of-bounds UVs
  adjustedUV = clamp(adjustedUV, vec2(0.0), vec2(1.0));

  //---- First Texture
  vec4 firstT = texture(uFirstTexture, adjustedUV);

  //---- Second Texture
  vec4 secondT = texture(uSecondTexture, adjustedUV);

  //---- Mask
  float mask = texture(uMaskTexture, vUv).r;
  float maskNoise = 0.;
  //remap progress
  float mapProgress = uProgress * 2. - 1.;
  float interpolation = 0.;

  // Y axis
  if(uCropH == 0.) {
    maskNoise = snoise(vUv.yx * sin(uProgress + adjustedUV.y) * rand(vec2(0.1, 0.5)));
    mask += maskNoise;

    interpolation = 1. - smoothstep(vUv.y + mapProgress, vUv.y + mapProgress, mask);
  }
  // X axis
  else{
    maskNoise = snoise(vUv.xy * sin(uProgress + adjustedUV.x) * rand(vec2(0.05, 0.5)));
    mask += maskNoise;
    
    interpolation = 1. - smoothstep(vUv.x + mapProgress, vUv.x + mapProgress, mask);
  }

  outColor = mix(firstT, secondT, interpolation);
}
