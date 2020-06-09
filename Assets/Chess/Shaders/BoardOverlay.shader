﻿Shader "ChessBot/BoardOverlay"
{
    Properties
    {
        _Color1 ("Board Color 1", Color) = (1,1,1,1)
        _Color2 ("Board Color 2", Color) = (0,0,0,1)
        _Color3 ("Piece Color 1", Color) = (1,1,1,1)
        _Color4 ("Piece Color 2", Color) = (0,0,0,1)
        _Color5 ("Selected Color", Color) = (1,0,0,1)
        _Color6 ("Valid Move Color", Color) = (0,1,0,1)
        _Color7 ("Final Selection Color", Color) = (0,0,1,1)
        _AtlasTex ("Chess Pieces Atlas", 2D) = "white" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _Pixel ("Pixel Check", Vector) = (0, 255, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

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
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float4 _Color5;
            float4 _Color6;
            float4 _Color7;
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
                // float3 col = fmod(dot(uv_id, 1..xx), 2);
                // col = lerp(_Color2, _Color1, col.r);
                float4 col = 0.0;
                float2 grid_uv = fmod(i.uv * 8, 1.);

                uint4 board[2] = { LoadValueUint(_BufferTex, _Pixel * 2),
                    LoadValueUint(_BufferTex, _Pixel * 2 + uint2(1, 0)) };

                // uint4 fullBoard[4] = {
                //     fullTests[2][0], fullTests[2][1],
                //     fullTests[2][2], fullTests[2][3]
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

                // uint curPos = getPiece(board, uv_id);

                // float2 piecePos = 0.14286 * float2((curPos & kMask), (curPos >> 3));
                // float4 pc = tex2D(_AtlasTex, grid_uv * 0.14286 + piecePos);
                // pc.rgb = lerp(_Color4, _Color3, smoothstep(0, 1, dot(pc.rgb, 1..xxx) * 0.5));

                float4 playerPosState = LoadValueFloat(_BufferTex, txPlayerPosState);
                col = lerp(col, _Color5, playerPosState.x > -1 && all(uint2(playerPosState.xy) == uv_id));
                
                float4 playerSrcDest = LoadValueFloat(_BufferTex, txPlayerSrcDest);
                col = lerp(col, _Color7, playerSrcDest.x > -1 && all(uint2(playerSrcDest.xy) == uv_id));
                
                float2 kingMoved = LoadValueFloat(_BufferTex, txKingMoved);
                bool clear = validMove(board, playerSrcDest.xy, uv_id, kingMoved);
                col = lerp(col, _Color6, clear);

                // col = lerp(col, pc, pc.a);

                return col;
            }
            ENDCG
        }
    }
}
