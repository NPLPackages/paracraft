void vsMain
(float inVertexID:POSITION
,out float4 outPosition:POSITION
,out float2 outUV:TEXCOORD0
)
{
  float2 pos_t;
  if(0.5>inVertexID)
  {
    pos_t=float2(-1.0,1.0);
    outUV=float2(0,0);
  }
  else if(1.5>inVertexID)
  {
    pos_t=float2(1.0,1.0);
    outUV=float2(1.0,0);
  }
  else if(2.5>inVertexID)
  {
    pos_t=float2(-1.0,-1.0);
    outUV=float2(0,1.0);
  }
  else
  {
    pos_t=float2(1.0,-1.0);
    outUV=float2(1.0,1.0);
  }
  outPosition=float4(pos_t,1.0,1.0);
}
float3 gInverseLightDirection;
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
void psMain
(float2 inUV:TEXCOORD0
,float2 inPositionWVP:TEXCOORD1
,out float4 outDiffse:COLOR0
)
{
  outDiffse=0;
  float3 normal=tex2Dlod(gMRTNormalSampler,float4(inUV,0,0)).rgb;
  normal=normal*2.0-1.0;
  outDiffse.b=saturate(dot(normal,gInverseLightDirection));
}
technique T
{
  pass P
  {
    VertexShader=compile vs_3_0 vsMain();
    PixelShader=compile ps_3_0 psMain();
    ColorWriteEnable=blue;
    ZWriteEnable=false;
    ZFunc=greater;
    CullMode=none;
    AlphaBlendEnable=true;
    DestBlend=one;
  }
}
