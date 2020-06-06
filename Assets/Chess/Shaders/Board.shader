Shader "ChessBot/Board"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (0,0,0,1)
        _Color3 ("Color 3", Color) = (1,1,1,1)
        _Color4 ("Color 4", Color) = (0,0,0,1)
        _AtlasTex ("Chess Pieces Atlas", 2D) = "white" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        [HideInInspector]_Pixel ("Pixel Check", Vector) = (0, 255, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "BotInclude.cginc"
            //#include "Debugging.cginc"
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

            Texture2D<float4> _BufferTex;
            sampler2D _AtlasTex;
            float3 _Color1;
            float3 _Color2;
            float3 _Color3;
            float3 _Color4;
            uint2 _Pixel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                uint2 uv_id = floor(i.uv * 8);
                float3 col = fmod(dot(uv_id, 1..xx), 2);
                col = lerp(_Color2, _Color1, col.r);
                float2 grid_uv = fmod(i.uv * 8, 1.);

                uint4 board[2] = { LoadValueUint(_BufferTex, _Pixel * 2),
                    LoadValueUint(_BufferTex, _Pixel * 2 + uint2(1, 0)) };

                // uint4 fullBoard[4] = {
                //     fullTests[1][0], fullTests[1][1],
                //     fullTests[1][2], fullTests[1][3]
                // };
                // uint4 board[2] = { fullBoard[0], fullBoard[1] };

                // uint2 srcPieceID = uint2(9, 12);
                // int2 src = int2(4, 3);
                // int2 dest = int2(3, 4);

                // uint4 nextBoard[4] = {
                //     doMove(fullBoard, 0, srcPieceID, src, dest, 0),
                //     doMove(fullBoard, 1, srcPieceID, src, dest, 0),
                //     doMove(fullBoard, 2, srcPieceID, src, dest, 0),
                //     doMove(fullBoard, 3, srcPieceID, src, dest, 0)
                // };

                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // srcPieceID = uint2(5, 3);
                // src = int2(3, 7);
                // dest = int2(3, 4);

                // fullBoard[0] = nextBoard[0];
                // fullBoard[1] = nextBoard[1];
                // fullBoard[2] = nextBoard[2];
                // fullBoard[3] = nextBoard[3];

                // nextBoard[0] = doMove(fullBoard, 0, srcPieceID, src, dest, 0);
                // nextBoard[1] = doMove(fullBoard, 1, srcPieceID, src, dest, 0);
                // nextBoard[2] = doMove(fullBoard, 2, srcPieceID, src, dest, 0);
                // nextBoard[3] = doMove(fullBoard, 3, srcPieceID, src, dest, 0);
                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // srcPieceID = uint2(9, 11);
                // src = int2(3, 1);
                // dest = int2(3, 3);

                // fullBoard[0] = nextBoard[0];
                // fullBoard[1] = nextBoard[1];
                // fullBoard[2] = nextBoard[2];
                // fullBoard[3] = nextBoard[3];

                // nextBoard[0] = doMove(fullBoard, 0, srcPieceID, src, dest, 0);
                // nextBoard[1] = doMove(fullBoard, 1, srcPieceID, src, dest, 0);
                // nextBoard[2] = doMove(fullBoard, 2, srcPieceID, src, dest, 0);
                // nextBoard[3] = doMove(fullBoard, 3, srcPieceID, src, dest, 0);
                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // srcPieceID = uint2(1, 12);
                // src = int2(4, 4);
                // dest = int2(4, 3);

                // fullBoard[0] = nextBoard[0];
                // fullBoard[1] = nextBoard[1];
                // fullBoard[2] = nextBoard[2];
                // fullBoard[3] = nextBoard[3];

                // nextBoard[0] = doMove(fullBoard, 0, srcPieceID, src, dest, 0);
                // nextBoard[1] = doMove(fullBoard, 1, srcPieceID, src, dest, 0);
                // nextBoard[2] = doMove(fullBoard, 2, srcPieceID, src, dest, 0);
                // nextBoard[3] = doMove(fullBoard, 3, srcPieceID, src, dest, 0);
                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // srcPieceID = uint2(9, 10);
                // src = int2(2, 1);
                // dest = int2(2, 3);

                // fullBoard[0] = nextBoard[0];
                // fullBoard[1] = nextBoard[1];
                // fullBoard[2] = nextBoard[2];
                // fullBoard[3] = nextBoard[3];

                // nextBoard[0] = doMove(fullBoard, 0, srcPieceID, src, dest, 0);
                // nextBoard[1] = doMove(fullBoard, 1, srcPieceID, src, dest, 0);
                // nextBoard[2] = doMove(fullBoard, 2, srcPieceID, src, dest, 0);
                // nextBoard[3] = doMove(fullBoard, 3, srcPieceID, src, dest, 0);
                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // srcPieceID = uint2(5, 3);
                // src = int2(3, 4);
                // dest = int2(3, 3);

                // fullBoard[0] = nextBoard[0];
                // fullBoard[1] = nextBoard[1];
                // fullBoard[2] = nextBoard[2];
                // fullBoard[3] = nextBoard[3];

                // nextBoard[0] = doMove(fullBoard, 0, srcPieceID, src, dest, 0);
                // nextBoard[1] = doMove(fullBoard, 1, srcPieceID, src, dest, 0);
                // nextBoard[2] = doMove(fullBoard, 2, srcPieceID, src, dest, 0);
                // nextBoard[3] = doMove(fullBoard, 3, srcPieceID, src, dest, 0);
                // board[0] = nextBoard[0];
                // board[1] = nextBoard[1];

                // buffer[0] = (nextBoard[3][2] & 0xff);

                uint curPos = getPiece(board, uv_id);

                float2 piecePos = 0.14286 * float2((curPos & kMask), (curPos >> 3));
                float4 pc = tex2D(_AtlasTex, grid_uv * 0.14286 + piecePos);
                pc.rgb = lerp(_Color4, _Color3, smoothstep(0, 1, dot(pc.rgb, 1..xxx) * 0.5));

                float4 playerPosState = LoadValueFloat(_BufferTex, txPlayerPosState);
                col = lerp(col, float3(1., 0., 0.), playerPosState.x > -1 && all(uint2(playerPosState.xy) == uv_id));
                
                float4 playerSrcDest = LoadValueFloat(_BufferTex, txPlayerSrcDest);
                col = lerp(col, float3(0., 0., 1.), playerSrcDest.x > -1 && all(uint2(playerSrcDest.xy) == uv_id));
                
                float2 kingMoved = LoadValueFloat(_BufferTex, txKingMoved);
                bool clear = validMove(board, playerSrcDest.xy, uv_id, kingMoved);
                col = lerp(col, float3(0., 1., 0.), clear);

                col = lerp(col.rgb, pc.rgb, pc.a);

                return float4(col, 1.);
            }
            ENDCG
        }
    }
}
