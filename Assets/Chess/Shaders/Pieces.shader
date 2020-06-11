Shader "ChessBot/Pieces"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1, 1, 1, 1)
        _Color2 ("Color 2", Color) = (0, 0, 0, 1)
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
        _CubeAmount ("Cubemap Amount", Range(0.0, 1.0)) = 0.1
        _BumpMap ("BumpMap", 2D) = "bump" {}
        _Roughness ("Roughness", Range(0.0, 10.0)) = 0.0
        _RimPower ("Rim Power", Range(0.01, 3.0)) = 0.05
        _GrabPassAmount ("GrabPass Amount", Range(0.0, 1.0)) = 0.5
        //_Test ("test", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {

        Tags { "RenderType"="Transparent" "Queue"="Transparent" "LightMode"="ForwardBase" }
        LOD 200

        GrabPass { "_ChessGrabPass" }         

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "ChessInclude.cginc"
            #include "Layout.cginc"
            //#include "Debugging.cginc"

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
                float3 ambient_SH : TEXCOORD5;
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
            float _CubeAmount;
            //float4 _Test;

            // Offset to 0, 0 of the board
            // x, y is White and z, w is Black
            static const float4 pcTable[16] =
            {
                86.2, 38.3, 86.2, -124.9,
                74.7, 38.5, 74.3, -125.0,
                61.7, 38.3, 61.7, -124.8,
                49.3, 38.5, 49.3, -125.0,
                37.0, 38.3, 37.0, -124.8,
                24.8, 38.3, 24.8, -124.9,
                13.1, 38.6, 12.7, -125.1,
                0.4,  38.4, 0.4,  -124.9,
                86.4, 26.1, 86.4, -112.8,
                74.2, 26.1, 74.2, -112.9,
                61.9, 26.2, 61.9, -112.7,
                49.5, 26.2, 49.6, -112.8,
                37.3, 26.1, 37.3, -112.8,
                25.0, 26.2, 25.0, -112.7,
                12.7, 26.2, 12.7, -112.7,
                0.4,  26.2, 0.4,  -112.7
            };

            // The piece IDs are baked into the UV positions
            void movePiece (inout float4 vertex, in int2 uvID)
            {
                bool isBlack = uvID.y > 3;
                int id = uvID.x + (isBlack ? 1 - (uvID.y - 6) : uvID.y) * 8;
                uint4 board[2] = { LoadValueUint(_BufferTex, txCurBoardTL),
                    LoadValueUint(_BufferTex, txCurBoardTR) };

                // We use the IDs to figure out where the position is
                uint shift = pID[id] - (floor(pID[id] / 100) * 100);
                uint buff = (((isBlack ? board[1] : board[0])[floor(pID[id] / 100)])
                    >> shift) & 0xff;

                int2 pos = int2(buff >> 4, buff & 0xf) - 1;
                float2 offset = isBlack ? pcTable[id].zw : pcTable[id].xy;
                vertex.xz += (any(pos < 0)) ?
                    0 : (offset + float2(-12.33, 12.33) * pos);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;

                // Vertex IDs are baked into the second UV map
                movePiece(v.vertex, floor(v.uv2 * 8.0));

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.pieceCol = v.uv2.y < 0.5 ? _Color1 : _Color2;
                o.ambient_SH =  ShadeSH9(float4(o.worldNormal, 1.0));
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Hide the pieces in the touch controls since its on top of it
                if (unity_OrthoParams.w) discard;
                float4 col = i.pieceCol;

                // Skybox
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 reflection = reflect(-worldViewDir, i.worldNormal);
                float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, _Roughness);
                float3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);
                
                // Cubemap
                float4 reflcol = texCUBE (_Cube, reflection);

                float orim = dot(worldViewDir, i.worldNormal);
                float rim = saturate(pow(orim, _RimPower));
                float powRim = pow(1 - orim, 3);

                // Normal map for the grab pass
                float3 bump = UnpackNormal(tex2D(_BumpMap, i.uv));
                bump = ( -0.06 - bump ) * 0.09;
                float4 grab = tex2Dproj(_ChessGrabPass, (i.screenPos / i.screenPos.w +
                    float4(bump.r, bump.g, 0, 1.0 - rim)));
                grab.rgb = HueShift(grab.rgb, powRim * 2.5);

                // Lighting
                float3 lightDirection;
                float atten;

                // Directional light
                if(_WorldSpaceLightPos0.w == 0.0)
                {
                    atten = 1.0;
                }
                else
                {
                    float3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
                    float dist = length(fragmentToLightSource);
                    atten = 1.0/dist;
                }

                float3 diffuseReflection = atten * _LightColor0.xyz;

                float3 lightFinal = pow(UNITY_LIGHTMODEL_AMBIENT.xyz +
                    diffuseReflection + i.ambient_SH * 0.7, 0.8);

                col.rgb = min(((skyColor * (1.0 - _GrabPassAmount) +
                    _GrabPassAmount * grab.rgb) * col.rgb + col.rgb * (powRim) +
                    (reflcol.rgb * reflcol.rgb * _CubeAmount) * rim) * lightFinal, 1.4);
                
                return col;
            }
            ENDCG
        }
    }
}
