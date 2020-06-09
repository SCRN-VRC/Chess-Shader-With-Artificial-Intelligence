Shader "ChessBot/Pieces"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1, 1, 1, 1)
        _Color2 ("Color 2", Color) = (0, 0, 0, 1)
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
        _CubeAmout ("Cubemap Amount", Range(0.0, 1.0)) = 0.1
        _BumpMap ("BumpMap", 2D) = "bump" {}
        _Roughness ("Roughness", Range(0.0, 10.0)) = 0.0
        _RimPower ("Rim Power", Range(0.05, 3.0)) = 0.05
        _GrabPassAmount ("GrabPass Amount", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {

        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        GrabPass { "_ChessGrabPass" }         

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float4 pieceCol : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 worldNormal : TEXCOORD4;
            };

            Texture2D<float4> _BufferTex;
            sampler2D _ChessGrabPass;
            sampler2D _BumpMap;
            samplerCUBE _Cube;

            float4 _Color1;
            float4 _Color2;
            float _Roughness;
            float _RimPower;
            float _GrabPassAmount;
            float _CubeAmout;

            // -12.4
            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;



                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.pieceCol = v.uv2.y < 0.5 ? _Color1 : _Color2;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = i.pieceCol;

                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 reflection = reflect(-worldViewDir, i.worldNormal);
                float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, _Roughness);
                float3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);
                
                float4 reflcol = texCUBE (_Cube, reflection);

                float orim = dot(worldViewDir, i.worldNormal);
                float rim = saturate(pow(orim, _RimPower));
                float3 bump = UnpackNormal(tex2D(_BumpMap, i.uv));
                bump = ( -0.06 - bump ) * 0.09;
                float4 grab = tex2Dproj(_ChessGrabPass, UNITY_PROJ_COORD(i.screenPos +
                    float4(bump.r, bump.g, 0, 1.0 - rim)));

                return min((float4(skyColor, 1.0) * (1.0 - _GrabPassAmount) +
                    _GrabPassAmount * grab) * col + col * (pow(1.0 - orim, 2) / 1.2) +
                    (reflcol * reflcol * _CubeAmout) * rim, 1.5);
            }
            ENDCG
        }
    }
}
