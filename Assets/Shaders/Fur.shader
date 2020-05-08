Shader "TNTC/Fur"{

    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_Gain("Gain", Range(0,1)) = 0.5

        [Space]
        _Width("Width", Float) = 0.05
        _TopWidth("Top Width", Float) = 0.05
        _Height("Height", Float) = 0.5
        _HeightRandom("Height Random Factor", Float) = 0

        [Space]
        _Bending("Body bending factor", Range(0,1)) = 0
        _BendDirection ("Bend Direction", Vector) = (0, 0, 0, 0)
        

        [Space]
        _Tessellation("Tessellation", Range(1, 64)) = 1
    }

    CGINCLUDE
    #define PARTS 3

    #include "UnityCG.cginc"
	#include "Autolight.cginc"
    #include "Lighting.cginc"
    
    float _Height;
    float _HeightRandom;	
    float _Width;
    float _TopWidth;
    float3 _BendDirection;
    float _Bending;
    float _Tessellation;

    sampler2D _MainTex;
    float4 _MainTex_ST;
	float4 _TopColor;
	float4 _BottomColor;
	float _Gain;

    struct appdata{
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float2 uv : TEXCOORD0;
    };

    struct v2g{
        float4 vertex : SV_POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float2 uv : TEXCOORD0;
        float4 worldPos: TEXCOORD1; 
    };

    struct tess {
        float edge[3] : SV_TessFactor;
        float inside : SV_InsideTessFactor;
    };

    struct g2f{
	    float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
        float2 modeluv : TEXCOORD2;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
		float3 normal : NORMAL;
    };

    appdata vert(appdata v){
	    return v;
    }

    v2g tessVert(appdata v){
        v2g o;
        o.vertex = v.vertex;
        o.normal = v.normal;
        o.tangent = v.tangent;
        o.uv = v.uv;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        return o;
    }

    tess patchConstantFunction (InputPatch<appdata, 3> patch){
        tess f;
        f.edge[0] = _Tessellation;
        f.edge[1] = _Tessellation;
        f.edge[2] = _Tessellation;
        f.inside = _Tessellation;
        return f;
    }

    [UNITY_domain("tri")]
    [UNITY_outputcontrolpoints(3)]
    [UNITY_outputtopology("triangle_cw")]
    [UNITY_partitioning("integer")]
    [UNITY_patchconstantfunc("patchConstantFunction")]
    appdata hull (InputPatch<appdata, 3> patch, uint id : SV_OutputControlPointID){
        return patch[id];
    }

    [UNITY_domain("tri")]
    v2g domain(tess factors, OutputPatch<appdata, 3> patch, float3 barycentricCoordinates : SV_DomainLocation){
        appdata v;

        #define DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
            patch[0].fieldName * barycentricCoordinates.x + \
            patch[1].fieldName * barycentricCoordinates.y + \
            patch[2].fieldName * barycentricCoordinates.z;

        DOMAIN_PROGRAM_INTERPOLATE(vertex)
        DOMAIN_PROGRAM_INTERPOLATE(normal)
        DOMAIN_PROGRAM_INTERPOLATE(tangent)
        DOMAIN_PROGRAM_INTERPOLATE(uv)

        return tessVert(v);
    }

    float rand(float3 co){
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

    g2f createVertex(float3 pos, float2 uv, float3 normal, float2 modeluv){
        g2f o; 
        o.pos = UnityObjectToClipPos(pos); 
		o.uv = uv;
		o.normal = UnityObjectToWorldNormal(normal);
        o.modeluv = modeluv;

        o._ShadowCoord = ComputeScreenPos(o.pos);
        
		#if UNITY_PASS_SHADOWCASTER
			o.pos = UnityApplyLinearShadowBias(o.pos);
		#endif

		return o;
    }

    g2f createFeather(float3 vertexPosition, float width, float height, float2 uv, float2 modeluv, float bend, float3x3 transformMatrix){

        float3 vPoint = float3(width, height, 0);
        float3 tangentNormal = normalize(float3(0, -1, 0));
		float3 localNormal = mul(transformMatrix, tangentNormal);

        float3 position = vertexPosition + mul(transformMatrix, vPoint);

        float4 worldPos = mul(unity_ObjectToWorld, float4(position, 1));
        worldPos.x -= _BendDirection.x * bend;
        worldPos.y -= _BendDirection.y * bend;
        worldPos.z -= _BendDirection.z * bend;

        float3 v = mul(unity_WorldToObject, worldPos);

        return createVertex(v, uv, localNormal, modeluv);
    }

    [maxvertexcount(3 + PARTS * 2 + 1)]
    void geo(triangle v2g IN[3], inout TriangleStream<g2f> triStream){
        
        float3 pos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
        float3 vNormal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3;
    	float4 vTangent = (IN[0].tangent + IN[1].tangent + IN[2].tangent) / 3;
        float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
        float2 modeluv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
        float3 worldPos = (IN[0].worldPos + IN[1].worldPos + IN[2].worldPos) / 3;

        float3x3 tangentToLocal = float3x3(
            vTangent.x, vNormal.x, vBinormal.x,
            vTangent.y, vNormal.y, vBinormal.y,
            vTangent.z, vNormal.z, vBinormal.z
        );
     
        for (int i = 0; i < 3; i++){
            triStream.Append(
                createVertex( 
                    IN[i].vertex, 
                    float2(0, 0), 
                    IN[i].normal, 
                    IN[i].uv
                )
            );
        }

        triStream.RestartStrip();

        float height =  (rand(pos.zyx) * 2 - 1) * _HeightRandom + _Height;
        float width = _Width;
        float topWidth = _TopWidth;

        for (int p = 0; p < PARTS; p++){
			float t = p / (float)PARTS;

			float pHeight = height * t;
			float pWidth = lerp(width, topWidth, t);

			triStream.Append(createFeather(pos, pWidth, pHeight,  float2(0, t), modeluv, _Bending * t, tangentToLocal));
			triStream.Append(createFeather(pos, -pWidth, pHeight,  float2(1, t), modeluv, _Bending * t, tangentToLocal));
		}

		triStream.Append(createFeather(pos, 0, height, float2(0.5, 1), modeluv, 1, tangentToLocal));
        triStream.RestartStrip();
    }

    ENDCG

    SubShader{
		Cull Off

        Pass{

			Tags{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.6
            #pragma multi_compile_fwdbase
            #pragma geometry geo
            #pragma hull hull
            #pragma domain domain
            

            float4 frag (g2f i) : SV_Target{
                fixed4 tex = tex2Dlod(_MainTex, float4(i.modeluv, 0, 0));	
				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = saturate(saturate(dot(i.normal, _WorldSpaceLightPos0)) + _Gain) * shadow;

				float3 ambient = ShadeSH9(float4(i.normal, 1));
				float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);

				float4 col = lerp(_BottomColor, _TopColor, i.uv.y) * tex * lightIntensity;
				return col;
            }

            ENDCG
        }

        Pass{
			
            Tags{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(g2f i) : SV_Target{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}

    }

}
