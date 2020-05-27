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
            #include "Layout.cginc"

            /*
                Max moves per piece
                Piece  Rq  Rk  Nq  Nk  Bq  Bk  Q   K  P
                Moves  16  16  8   8   15  15  31  9  32  =  150 possible moves

                Every board generates 150 boards, one board is 2x2 pixels
                300 x 2 pixels generated per board
            */

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
                ID = Column id
            */
            void doMoveParams (in uint4 boardInput[4], in uint ID, in uint turn,
                out uint2 srcPieceID, out int2 src, out int2 dest)
            {

                uint idx_t = ID.x;

                // Pawns
                if (idx_t < moveNum[PAWN].y)
                {
                    // Each unique pawn have 4 moves each
                    // pID for pawns goes from 8 to 15
                    srcPieceID = uint2(PAWN, floor(idx_t / 4) + 8);
                    dest = (turn == WHITE ? pawnListW[idx_t % 4] :
                                            pawnListB[idx_t % 4]);
                }
                // Knights
                else if (idx_t < moveNum[KNIGHT].y)
                {
                    idx_t -= moveNum[PAWN].y;
                    srcPieceID = uint2(KNIGHT,
                        idx_t < uint(moveNum[KNIGHT].x * 0.5) ? 1 : 6);
                    dest = knightList[idx_t % 8];
                }
                // Bishops
                else if (idx_t < moveNum[BISHOP].y)
                {
                    idx_t -= moveNum[KNIGHT].y;
                    srcPieceID = uint2(BISHOP,
                        idx_t < uint(moveNum[BISHOP].x * 0.5) ? 2 : 5);
                }
                // Rooks
                else if (idx_t < moveNum[ROOK].y)
                // King side rooks don't shift
                {
                    idx_t -= moveNum[BISHOP].y;
                    srcPieceID = uint2(ROOK,
                        idx_t < uint(moveNum[ROOK].x * 0.5) ? 0 : 7);
                }
                // Queen
                // Kings/Queens don't need shifts srcPieceID.y shifts
                else if (idx_t < moveNum[QUEEN].y)
                { srcPieceID = uint2(QUEEN, 3); }
                // King
                else if (idx_t < moveNum[KING].y)
                {
                    idx_t -= moveNum[QUEEN].y;
                    srcPieceID = uint2(KING, 4);
                    dest = kingList[idx_t % 8];
                }
                else srcPieceID = uint2(0, 0);

                srcPieceID.x += turn << 3;

                // Find the source position
                uint shift = pID[srcPieceID.y] -
                    (floor(pID[srcPieceID.y] / 100) * 100);
                uint buff = ((boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
                    [floor(pID[srcPieceID.y] / 100)]) >> shift) & 0xff;
                
                //buffer[0] = float4(buff.xxxx);

                // The board saves positions in (y, x) format
                // y, x to x, y make sure to -1 
                src = int2(buff & 0xf, buff >> 4) - 1;

                // Reset ID
                idx_t = ID.x;

                // Pawns
                if (idx_t < moveNum[PAWN].y)
                { dest = src + dest; }
                // Knights
                else if (idx_t < moveNum[KNIGHT].y)
                { dest = src + dest; }
                // Bishops
                else if (idx_t < moveNum[BISHOP].y)
                {
                    idx_t -= moveNum[KNIGHT].y;
                    int4 bOrigin = getBishopOrigin(src);
                    // King/Queen side
                    uint IDcond = fmod(idx_t, moveNum[BISHOP].x * 0.5);
                    [flatten]
                    // Queen side
                    if (idx_t < uint(moveNum[BISHOP].x * 0.5))
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
                // Rooks
                else if (idx_t < moveNum[ROOK].y)
                {
                    idx_t -= moveNum[BISHOP].y;
                    // Half of the move-set goes horizontal, half vertical
                    uint idMod = fmod(idx_t, moveNum[ROOK].x * 0.5);
                    uint r = moveNum[ROOK].x * 0.25;
                    dest.x = idMod < r ? idMod : src.x ;
                    dest.y = idMod < r ? src.y : idMod - r ;
                }
                // Queen
                else if (idx_t < moveNum[QUEEN].y)
                {
                    idx_t -= moveNum[ROOK].y;
                    [flatten]
                    // Rook like movement
                    if (idx_t < uint(moveNum[ROOK].x * 0.5)) {
                        uint r = moveNum[ROOK].x * 0.25;
                        dest.x = idx_t < r ? idx_t : src.x ;
                        dest.y = idx_t < r ? src.y : idx_t - r ;
                    }
                    // Bishop like movement
                    else {
                        // FIX THIS, unsigned range conversion
                        idx_t -= moveNum[ROOK].x * 0.5;
                        int4 bOrigin = getBishopOrigin(src);
                        // Different moves on white/black tiles
                        bool onBlack = (src.x % 2 == src.y % 2);
                        // [flatten]
                        // if (idx_t < moveNum[BISHOP].x * 0.5)
                        // {
                            dest = idx_t < (onBlack ? 7 : 8) ?
                                bOrigin.xy + int2(-1, 1) * idx_t :
                                bOrigin.zw + int2(1, 1) * (idx_t - (onBlack ? 7 : 8));
                        // }
                    }
                }
                // King
                else if (idx_t < moveNum[KING].y)
                { dest = src + dest; }
            }

            // Given the board ID, return the parent position
            // of the generated board
            int2 findParentBoard(int boardSetID)
            {
                return boardSetID == 0 ?
                    txCurBoardBL :
                    int2((boardSetID - 1) * 2, 0) ;
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

            float4 frag (v2f ps) : SV_Target
            {
                clip(ps.uv.z);
                uint2 px = floor(ps.uv.xy * _ScreenParams.xy);
                uint4 col = 0;

                // UVs of set of boards generated per board
                float2 boardsUV = fmod(px, boardParams.xy) / boardParams.xy;

                // UVs of a single board (2x2)
                float4 singleUV_ID = 0;
                singleUV_ID.xy = fmod(px, 2..xx);
                // ID of each corner
                singleUV_ID.z = singleUV_ID.y * 2 + singleUV_ID.x;

                // // ID for each board, 22500 total
                // singleUV_ID.xy = fmod(floor(ps.uv.xy * _ScreenParams.xy * 0.5),
                //     boardParams.zw * 0.5);
                // singleUV_ID.w = singleUV_ID.y * (boardParams.w * 0.5) + singleUV_ID.x;

                // ID for each set of boards, 150 total
                uint boardSetID = floor(ps.uv.y * _ScreenParams.y * 0.5);

                uint4 turn = LoadValue(_BufferTex, txTurn);
                turn.x = _Time.y <= 1.0 ? 1 : turn.x;

                [branch]
                // Parameters to save
                if (px.y >= uint(txCurBoardBL.y))
                {
                    uint4 curBoard[4];
                    curBoard[B_LEFT] =  LoadValue(_BufferTex, txCurBoardBL);
                    curBoard[B_RIGHT] = LoadValue(_BufferTex, txCurBoardBR);
                    curBoard[T_LEFT] =  LoadValue(_BufferTex, txCurBoardTL);
                    curBoard[T_RIGHT] = LoadValue(_BufferTex, txCurBoardTR);

                    if (turn.x == 1) {
                        curBoard[B_LEFT] = newBoard(B_LEFT);
                        curBoard[B_RIGHT] = newBoard(B_RIGHT);
                        curBoard[T_LEFT] = newBoard(T_LEFT);
                        curBoard[T_RIGHT] = newBoard(T_RIGHT);
                    }

                    StoreValue(txCurBoardBL, curBoard[B_LEFT], col,  px);
                    StoreValue(txCurBoardBR, curBoard[B_RIGHT], col, px);
                    StoreValue(txCurBoardTL, curBoard[T_LEFT], col,  px);
                    StoreValue(txCurBoardTR, curBoard[T_RIGHT], col, px);
                    StoreValue(txTurn, turn, col, px);
                }
                // Actual board
                if (all(px < uint2(boardParams.zw)))
                //if (all(px == int2(6, 0)))
                {
                    int2 parentPos = findParentBoard(boardSetID);
                    uint4 parentBoard[4];
                    parentBoard[B_LEFT] =  LoadValue(_BufferTex, parentPos);
                    parentBoard[B_RIGHT] = LoadValue(_BufferTex, parentPos + int2(1, 0));
                    parentBoard[T_LEFT] =  LoadValue(_BufferTex, parentPos + int2(0, 1));
                    parentBoard[T_RIGHT] = LoadValue(_BufferTex, parentPos + int2(1, 1));
                    
                    uint2 srcPieceID = 0;
                    int2 src = 0;
                    int2 dest = 0;

            // void doMoveParams (in uint4 boardInput[4], in uint ID, in uint turn,
            //     out uint2 srcPieceID, out int2 src, out int2 dest)

                    doMoveParams(parentBoard, floor(px.x * 0.5), turn.x,
                        srcPieceID, src, dest);

            // uint4 doMove(in uint4 boardPosArray[4], in uint posID, in uint2 srcPieceID,
            //     in int2 source, in int2 dest)
            
                    // uint4 board[2] = { parentBoard[0], parentBoard[1] };
                    // buffer[0] = float4(dest, validMove(board, src, dest).xx);
                    col = doMove(parentBoard, uint(singleUV_ID.z),
                        srcPieceID, src, dest);
                }

                return col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
