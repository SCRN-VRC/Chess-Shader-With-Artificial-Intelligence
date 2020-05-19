Shader "ChessBot/Controller"
{
    Properties
    {
        _AlphaBetaTex ("AlphaBeta Pruning Output", 2D) = "black" {}
        _BufferTex ("Buffer", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv * 2 - 1, 0, 1);
                #ifdef UNITY_UV_STARTS_AT_TOP
                v.uv.y = 1-v.uv.y;
                #endif
                o.uv = UnityStereoTransformScreenSpaceTex(v.uv);
                return o;
            }

            sampler2D _BufferTex;
            float4 _BufferTex_ST;
            
            fixed4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDCG
        }
    }
}
