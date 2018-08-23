// Author: LiXizhi@yeah.net
// Date: 2015/5/22
// Desc: block max model shader.

////////////////////////////////////////////////////////////////////////////////
//  Per frame parameters
float4x4 mWorldViewProj : worldviewprojection;
float4x4 mWorldView: worldview;
float4x4 mWorld: world;

float3	colorDiffuse:materialdiffuse;
float3	colorAmbient:ambientlight;
/** x is sun light strength, y is block light strength. */
float3	BlockLightStrength: LightStrength;
float g_opacity : opacity = 1.0;

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
	output.normal = worldNormal*0.5 + 0.5;

	output.color.xyz = color.rgb * colorDiffuse;

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
	output.Color = float4(input.color.rgb, g_opacity);
	output.BlockInfo = float4(1, BlockLightStrength.x, BlockLightStrength.y, 1);
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
