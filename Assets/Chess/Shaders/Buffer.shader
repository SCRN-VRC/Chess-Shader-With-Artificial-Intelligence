Shader "ChessBot/Buffer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxDist ("Max Distance", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        Lighting Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D<float4> _MainTex;
            float _MaxDist;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv * 2 - 1, 0, 1);
                #ifdef UNITY_UV_STARTS_AT_TOP
                v.uv.y = 1-v.uv.y;
                #endif
                o.uv.xy = UnityStereoTransformScreenSpaceTex(v.uv);
                o.uv.z = distance(_WorldSpaceCameraPos,
                    mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz) > _MaxDist ?
                    -1 : 1;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                clip(i.uv.z);
                // sample the texture
                float4 col = _MainTex.Load(int3(i.uv.xy * _ScreenParams, 0));
                return col;
            }
            ENDCG
        }
    }
}
