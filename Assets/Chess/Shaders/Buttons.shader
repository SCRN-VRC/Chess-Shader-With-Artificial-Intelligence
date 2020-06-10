Shader "ChessBot/Buttons"
{
    Properties
    {
        _MainTex ("Button Texture", 2D) = "black" {}
        _StatusTex ("Status Texture", 2D) = "black" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _Color1 ("Highlight Color", Color) = (1,0,0,1)
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
            #include "ChessInclude.cginc"
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
            float4 _Color1;

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
                
                // Split the uvs into two
                float2 buv = i.uv;
                buv.y *= 1.3333;
                float2 tuv = i.uv;
                int2 uv_id = floor(buv * 2);

                float4 turnWinUpdateLate = LoadValueFloat(_BufferTex, txTurnWinUpdateLate);
                float4 drawResignNewReset = LoadValueFloat(_BufferTex, txDrawResignNewReset);
                float4 buttonPos = LoadValueFloat(_BufferTex, txButtonPos);

                [flatten]
                if (i.uv.y > 0.75)
                {
                    [flatten]
                    if (turnWinUpdateLate.y == WHITE) {}
                    else if (turnWinUpdateLate.y == BLACK) { tuv.y -= 0.25; }
                    else if (turnWinUpdateLate.y == DRAW_ACCEPT) { tuv.y -= 0.5; }
                    else if (turnWinUpdateLate.y == DRAW_DECLINE) { tuv.y -= 0.75; }
                    else { tuv.y += 0.25; }
                    col = tex2D(_StatusTex, tuv);
                }
                else
                {
                    col = tex2D(_MainTex, buv);
                    col = lerp(col, _Color1, (buttonPos.z > 0 && all(int2(buttonPos.xy) == uv_id)) * 0.5 * col.a);
                }
                return col;
            }
            ENDCG
        }
    }
}
