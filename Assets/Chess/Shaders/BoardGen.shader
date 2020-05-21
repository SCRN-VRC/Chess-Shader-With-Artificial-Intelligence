Shader "ChessBot/BoardGen"
{
    Properties
    {
        _BufferTex ("Buffer", 2D) = "black" {}
        _MaxDist ("Max Distance", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "BotInclude.cginc"
            #include "Debugging.cginc"

            Texture2D<float4> _BufferTex;
            float _MaxDist;

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            /*
                ID.x = Column id
                ID.y = Row id
            */
            uint4 genNewBoard (uint4 boardInput[4], uint2 ID, uint turn)
            {
                uint2 srcPieceID = 0;
                int2 src = 0;
                int2 dest = 0;

                [flatten]
                // Rooks, queen side then king side
                // srcPieceID.y contains the pID index for shifting
                if (ID.x < 28)
                // King side rooks don't shift
                { srcPieceID = uint2(ROOK, ID.x < 14 ? 0 : 7); }
                // Knights
                else if (ID.x < 44)
                {
                    srcPieceID = uint2(KNIGHT, ID.x < 36 ? 1 : 6);
                    dest = knightList[(ID.x - 28) % 8];
                }
                // Bishops
                else if (ID.x < 74)
                { srcPieceID = uint2(BISHOP, ID.x < 59 ? 2 : 5); }
                // Queen
                // Kings/Queens don't need shifts srcPieceID.y shifts
                else if (ID.x < 105)
                { srcPieceID = uint2(QUEEN, 3); }
                // King
                else if (ID.x < 114)
                {
                    srcPieceID = uint2(KING, 4);
                    dest = kingList[ID.x - 105];
                }
                // Pawns
                else if (ID.x < 146)
                {
                    // Each unique pawn have 4 moves each
                    // pID for pawns goes from 8 to 15
                    srcPieceID = uint2(PAWN, floor((ID.x - 114) / 4) + 8);
                    dest = (turn == WHITE ? pawnListW[(ID.x - 114) % 4] :
                                            pawnListB[(ID.x - 114) % 4]);
                }

                srcPieceID.x += turn << 3;

                // Find the source position
                uint shift = srcPieceID.y - (floor(srcPieceID.y / 100) * 100);
                uint buff = ((boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
                    [floor(pID[srcPieceID.y] / 100)]) >> shift) & 0xff;

                // Remember the board saves positions in (y, x) format
                // y, x to x, y
                src = int2(buff & 0xf, buff >> 4);

                // Calculate destination based on source
                [flatten]
                // Rooks
                if (ID.x < 28)
                {
                    // Half of the move-set goes horizontal, half vertical
                    uint idMod = (ID.x % 14);
                    dest.x = idMod < 7 ? idMod : src.x ;
                    dest.y = idMod < 7 ? src.y : idMod - 7 ;
                }
                // Knights, do nothing
                else if (ID.x < 44) { dest = src + dest; }
                // Bishops
                else if (ID.x < 74)
                {
                    int4 bOrigin = getBishopOrigin(src);
                    uint IDcond = (ID.x % 15); // King/Queen side
                    [flatten]
                    // Queen side
                    if (ID.x < 59)
                    {
                        // Since the bishop moves aren't mirror for the black pieces
                        dest = IDcond < (turn ? 7 : 8) ?
                            bOrigin.xy + int2(-1, 1) * IDcond :
                            bOrigin.zw + int2(1, 1) * (IDcond - (turn ? 7 : 8));
                    }
                    // King side
                    else
                    {
                        dest = IDcond < (turn ? 7 : 8) ?
                            bOrigin.zw + int2(1, 1) * IDcond :
                            bOrigin.xy + int2(-1, 1) * (IDcond - (turn ? 7 : 8));
                    }
                }
                // Queen
                else if (ID.x < 105)
                {
                    // Half of the move-set goes horizontal, half vertical
                    [flatten]
                    // Rook like movement CHECK LOGIC
                    if (ID.x - 74 < 28) {
                        uint idMod = ((ID.x - 74) % 14);
                        dest.x = idMod < 7 ? idMod : src.x ;
                        dest.y = idMod < 7 ? src.y : idMod - 7 ;
                    }
                    // Bishop like movement
                    else {

                    }
                }
                // King and pawns
                else if (ID.x < 146) { dest = src + dest; }

                //doMove(uint4 boardPosArray[4], uint posID, uint2 srcPieceID,
                //    int2 source, int2 dest)
                return doMove(boardInput, ID.y, srcPieceID, src, dest);

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv * 2 - 1, 0, 1);
                #ifdef UNITY_UV_STARTS_AT_TOP
                v.uv.y = 1-v.uv.y;
                #endif
                o.uv.xy = UnityStereoTransformScreenSpaceTex(v.uv);
                o.uv.z = distance(_WorldSpaceCameraPos,
                    mul(unity_ObjectToWorld, fixed4(0,0,0,1)).xyz) > _MaxDist ?
                    -1 : 1;
                return o;
            }

            /*
                Max moves per piece
                Piece  Rq  Rk  Nq  Nk  Bq  Bk  Q   K  P
                Moves  14  14  8   8   15  15  31  9  32  =  146 possible moves

                Every board generates 146 boards, one board is 2x2 pixels
                292 x 2 pixels generated per board
            */

            #define BOARD_DIM      float2(292, 2)

            float4 frag (v2f ps) : SV_Target
            {
                clip(ps.uv.z);
                float4 col = 0;

                // UVs of set of boards generated per board
                float2 boardsUV = fmod(ps.uv.xy * _ScreenParams.xy,
                    BOARD_DIM) / BOARD_DIM;

                // UVs of a single board (2x2)
                uint3 singleUV_ID;
                singleUV_ID.xy = fmod(ps.uv.xy * _ScreenParams.xy, 2..xx);
                // ID of each corner
                singleUV_ID.z = singleUV_ID.y * 2 + singleUV_ID.x;

                // Board number
                uint boardID = ps.uv.y;

                col = newBoard(singleUV_ID.z);

                return col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
