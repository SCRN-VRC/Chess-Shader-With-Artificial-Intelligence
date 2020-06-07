Shader "Unlit/Buttons"
{
    Properties
    {
        _MainTex ("Button Texture", 2D) = "black" {}
        _StatusTex ("Status Texture", 2D) = "black" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Layout.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _StatusTex;
            Texture2D<float4> _BufferTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;
                int2 uv_id = floor(i.uv * 2);
                // Split the uvs into two
                float2 buv = i.uv;
                buv.y *= 1.3333;
                float2 tuv = i.uv;
                [flatten]
                if (i.uv.y < 0.75)
                {
                    col = tex2D(_MainTex, buv);
                }
                else
                {
                    tuv.y -= 0.75;
                    col = tex2D(_StatusTex, tuv);
                }
                return col;
            }
            ENDCG
        }
    }
}
