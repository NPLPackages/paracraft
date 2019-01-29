/*
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
float3 gInverseLightDirection;
float gLightRange;
float gLightHalfInnerAngleCos;
float gLightHalfOuterAngleCos;
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
  float diffuse=saturate(dot(normal,gInverseLightDirection));
  float3 position_wv;
  position_wv.xy=inPositionT.xy/float2(gProjectionMatrix[0][0],gProjectionMatrix[1][1])*view_depth;
  position_wv.z=view_depth;
  float3 world_position=mul(float4(position_wv,1.0),gInverseViewMatrix);
  float3 delta_vector_vertex_to_light=gLightPosition-world_position;
  float3 vertex_to_light_direction=normalize(delta_vector_vertex_to_light);
  float fall_off0=saturate(pow(length(delta_vector_vertex_to_light)/gLightRange,2));
  float fall_off1=saturate((gLightHalfInnerAngleCos-dot(vertex_to_light_direction,gInverseLightDirection))/(gLightHalfInnerAngleCos-gLightHalfOuterAngleCos));
  outDiffuse.b=diffuse*(1.0-fall_off0)*(1.0-fall_off1);
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
*/

float4x4 mWorldViewProj : worldviewprojection;
float4x4 mWorldView: worldview;
float4x4 mWorld: world;

float3	colorDiffuse:materialdiffuse;
float3	colorAmbient:ambientlight;
/** x is sun light strength, y is block light strength. */
float3	BlockLightStrength: LightStrength;
float g_opacity : opacity = 1.0;
float4	LightCenterPos: ConstVector0;

struct VSOut
{
	float4 pos	:POSITION;
	float4 color			: TEXCOORD0;		// diffuse color
	float3 normal				: TEXCOORD1;		// diffuse color
};

VSOut MainVS(float4 pos		: POSITION,
	float3	Norm : NORMAL,
	half4 color : COLOR0
)
{
	VSOut output;
	output.pos = mul(pos, mWorldViewProj);
	// camera space position
	float4 cameraPos = mul(pos, mWorldView);

	// world space normal
	float3 worldNormal = normalize(mul(Norm, (float3x3)mWorld));
	output.normal = worldNormal * 0.5 + 0.5;

	output.color.xyz = color.rgb;

	// calculate the fog factor
	output.color.w = cameraPos.z;
	return output;
}

struct BlockPSOut
{
	// standard color
	float4 Color	: COLOR0;
	// r is 32bits depth
	float4 Depth	: COLOR1;
	// r is category id, g is sun light, b is block light
	float4 BlockInfo : COLOR2;
	float4 Normal : COLOR3;
};

BlockPSOut MainPS(VSOut input)
{
	BlockPSOut output;
	// output.Color = float4(input.color.rgb, g_opacity);
	output.Color.xyz = LightCenterPos.xyz; output.Color.w = 1;
	output.BlockInfo = float4(1, BlockLightStrength.x, 1, 1);
	output.Depth = float4(input.color.w, 0, 0, 1);
	output.Normal = float4(input.normal.xyz, 1);
	return output;
}

////////////////////////////////////////////////////////////////////////////////
//
//                              shadow map : VS and PS
//
////////////////////////////////////////////////////////////////////////////////

void VertShadow(float4 Pos		: POSITION,
	float3	Norm : NORMAL,
	half4 color : COLOR0,
	out float4 oPos : POSITION,
	out float2 Depth : TEXCOORD1)
{
	oPos = mul(Pos, mWorldViewProj);
	Depth.xy = oPos.zw;
}

float4 PixShadow(float2 Depth : TEXCOORD1) : COLOR
{
	return float4(Depth.x, 0.0, 0.0, 1.0);
}

technique SimpleMesh_vs20_ps20
{
	pass P0
	{
		VertexShader = compile vs_2_0 MainVS();
		PixelShader = compile ps_2_0 MainPS();
		FogEnable = false;
	}
}

technique GenShadowMap
{
	pass p0
	{
		VertexShader = compile vs_2_a VertShadow();
		PixelShader = compile ps_2_a PixShadow();
		FogEnable = false;
	}
}
