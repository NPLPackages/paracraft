float4x4 gWorldViewProjectionMatrix;
void vsMain
(float3 inPosition:POSITION
,out float4 outPosition:POSITION
,out float2 outUV:TEXCOORD0
,out float2 outPositionT:TEXCOORD1
)
{
  outPosition=mul(float4(inPosition,1.0),gWorldViewProjectionMatrix);
  outPosition/=outPosition.w;
  outPosition.z=max(outPosition.z,0);
  outPositionT=outPosition.xy;
  outUV=outPositionT*float2(0.5,-0.5)+0.5;
}
float3 gLightPosition;
float gLightRange;
float4x4 gProjectionMatrix;
float4x4 gInverseViewMatrix;
texture gMRTNormalTexture;
sampler gMRTNormalSampler:register(s0) = sampler_state
{
	Texture = <gMRTNormalTexture>;
	MinFilter = Point;
	MagFilter = Point;
  MipFilter = None;
	AddressU = clamp;
	AddressV = clamp;
};
texture gMRTDepthTexture;
sampler gMRTDepthSampler:register(s1) = sampler_state
{
	Texture = <gMRTDepthTexture>;
	MinFilter = Point;
	MagFilter = Point;
  MipFilter = None;
	AddressU = clamp;
	AddressV = clamp;
};
void psMainBK(out float4 outDiffuse:COLOR0)
{
  outDiffuse=0;
}
void psMain
(float2 inUV:TEXCOORD0
,float2 inPositionT:TEXCOORD1
,out float4 outDiffuse:COLOR0
)
{
  outDiffuse=0;
  float view_depth=tex2Dlod(gMRTDepthSampler,float4(inUV,0,0)).r;
  float3 normal=tex2Dlod(gMRTNormalSampler,float4(inUV,0,0)).rgb;
  normal=normal*2.0-1.0;
  float3 position_wv;
  position_wv.xy=inPositionT.xy/float2(gProjectionMatrix[0][0],gProjectionMatrix[1][1])*view_depth;
  position_wv.z=view_depth;
  float3 world_position=mul(float4(position_wv,1.0),gInverseViewMatrix);
  float3 delta_vector_vertex_to_light=gLightPosition-world_position;
  float3 vertex_to_light_direction=normalize(delta_vector_vertex_to_light);
  float diffuse=saturate(dot(normal,vertex_to_light_direction));
  float fall_off=saturate(pow(length(delta_vector_vertex_to_light)/gLightRange,2));
  outDiffuse.b=diffuse*(1.0-fall_off);
}
technique T
{
  pass PBackFace
  {
    VertexShader=compile vs_3_0 vsMain();
    PixelShader=compile ps_3_0 psMainBK();
    ColorWriteEnable=0;
    ZWriteEnable=false;
    StencilEnable=true;
    StencilFunc=always;
    StencilRef=1;
    StencilPass=replace;
    ZFunc=greater;
    CullMode=cw;
  }
  pass PFrontFace
  {
    VertexShader=compile vs_3_0 vsMain();
    PixelShader=compile ps_3_0 psMain();
    ColorWriteEnable=blue;
    ZWriteEnable=false;
    StencilEnable=true;
    StencilFunc=equal;
    StencilRef=1;
    StencilPass=keep;
    ZFunc=lessequal;
    CullMode=ccw;
    AlphaBlendEnable=true;
    DestBlend=one;
  }
}
