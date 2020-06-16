#ifndef _CHESS_INCLUDE
#define _CHESS_INCLUDE

//#include "Debugging.cginc"
#include "Layout.cginc"

#define PAWN        1   // 0001
#define KNIGHT      2   // 0010
#define BISHOP      3   // 0011
#define ROOK        4   // 0100
#define QUEEN       5   // 0101
#define KING        6   // 0110

#define BLACK       0
#define WHITE       1

#define B_LEFT      0
#define B_RIGHT     1
#define T_LEFT      2
#define T_RIGHT     3

#define FLT_MIN     -1000000000.0
#define FLT_MAX     1000000000.0

// Pieces mask
static const uint pMask = 0xf;

// B\W side mask
static const uint sMask = 0x8;

// Piece w\o side mask
static const uint kMask = 0x7;

// Piece values

static const float pieceVal[7] =
{
    0, 70, 385, 400, 625, 1350, 2000000
};

// Piece ID to Search Array Index
static const uint2 searchID[7][2] =
{
    // Nothing, not used
    0, 0, 0, 0,
    // Pawns, not used
    2, 3, 2, 3,
    // Knights
    0, 16, 1, 8,
    // Bishops
    0, 8, 1, 16,
    // Rooks
    0, 24, 1, 0,
    // Queens
    0, 0, 0, 0,
    // Kings
    1, 24, 1, 24
};

// Piece IDs by index, array elements are values to shift by
static const uint pID[16] =
{
    // Queen side
    // R, N, B, Q
    24, 16, 8, 0,
    // King side
    // K, B, N, R
    124, 116, 108, 100,
    // Queen pawns
    224, 216, 208, 200,
    // King pawns
    324, 316, 308, 300
};

/*
    Bishop Move-set Table
    Given the source position, return the base position for
    destination

    x,y - left to right base position
    z,w - right to left base position
*/

static const int4 bishopTable[8][8] =
{
    7,0,0,7, 7,1,0,6, 7,2,0,5, 7,3,0,4, 7,4,0,3, 7,5,0,2, 7,6,0,1, 7,7,0,0,
    6,0,0,6, 7,0,0,5, 7,1,0,4, 7,2,0,3, 7,3,0,2, 7,4,0,1, 7,5,0,0, 7,6,1,0,
    5,0,0,5, 6,0,0,4, 7,0,0,3, 7,1,0,2, 7,2,0,1, 7,3,0,0, 7,4,1,0, 7,5,2,0,
    4,0,0,4, 5,0,0,3, 6,0,0,2, 7,0,0,1, 7,1,0,0, 7,2,1,0, 7,3,2,0, 7,4,3,0,
    3,0,0,3, 4,0,0,2, 5,0,0,1, 6,0,0,0, 7,0,1,0, 7,1,2,0, 7,2,3,0, 7,3,4,0,
    2,0,0,2, 3,0,0,1, 4,0,0,0, 5,0,1,0, 6,0,2,0, 7,0,3,0, 7,1,4,0, 7,2,5,0,
    1,0,0,1, 2,0,0,0, 3,0,1,0, 4,0,2,0, 5,0,3,0, 6,0,4,0, 7,0,5,0, 7,1,6,0,
    0,0,0,0, 1,0,1,0, 2,0,2,0, 3,0,3,0, 4,0,4,0, 5,0,5,0, 6,0,6,0, 7,0,7,0
};

// Change origin to bottom left
int4 getBishopOrigin(int2 src) {
    return bishopTable[7 - src.y][src.x];
}

// Piece-Square Tables
// https://www.chessprogramming.org/Simplified_Evaluation_Function

static const float pcTbl[8][8][8] =
{

    // nothing
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,

    // pawn
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-25,-25, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0,

     // knight
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,

    // bishop
    -20,-10,-10,-10,-10,-10,-10,-20,
    -40,  0,  0,  0,  0,  0,  0,-40,
    -15,  0,  5, 10, 10,  5,  0,-15,
    -15,  5,  5, 10, 10,  5,  5,-15,
    -15,  0, 10, 10, 10, 10,  0,-15,
    -15, 10, 10, 10, 10, 10, 10,-15,
    -15,  5,  0,  0,  0,  0,  5,-15,
    -20,-20,-20,-10,-10,-20,-20,-20,

    // rook
    0,  0,  0,  0,  0,  0,  0,  0,
    5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    0,  0,  0,  5,  5,  0,  0,  0,

    // queen
    -20,-10,-10, -5, -5,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5,  5,  5,  5,  0,-10,
     -5,  0,  5,  5,  5,  5,  0, -5,
      0,  0,  5,  5,  5,  5,  0, -5,
    -10,  5,  5,  5,  5,  5,  0,-10,
    -10,  0,  5,  0,  0,  0,  0,-10,
    -20,-10,-10, -5, -5,-10,-10,-20,

    // king mid game
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -10,-20,-20,-20,-20,-20,-20,-10,
     20, 20,  0,  0,  0,  0, 20, 20,
     20, 30, 10,  0,  0, 10, 30, 20,

    // king late game
    -50,-40,-30,-20,-20,-30,-40,-50,
    -30,-20,-10,  0,  0,-10,-20,-30,
    -30,-10, 20, 30, 30, 20,-10,-30,
    -30,-10, 30, 40, 40, 30,-10,-30,
    -30,-10, 30, 40, 40, 30,-10,-30,
    -30,-10, 20, 30, 30, 20,-10,-30,
    -30,-30,  0,  0,  0,  0,-30,-30,
    -50,-30,-30,-30,-30,-30,-30,-50
};

// Change origin to bottom left
// Flip board if it's black
float getBoardScore(int2 src, int z, int w) {
    if ((src.x + src.y) <= 0) return 0;
    return pcTbl[z][w == WHITE ? 7 - src.y : src.y][src.x];
}

// List of moves
static const int2 pawnListW[4] = { -1, 1, 1, 1, 0, 1, 0, 2 };
static const int2 pawnListB[4] = { -1, -1, 1, -1, 0, -1, 0, -2 };
static const int2 knightList[8] = { -1, 2, -2, 1, -2, -1, -1, -2, 1,
    -2, 2, -1, 2, 1, 1, 2 };
static const int2 kingList[10] = { 0, 1, 1, 1, 1, 0, 1, -1,
    0, -1, -1, -1, -1, 0, -1, 1, -2, 0, 2, 0 };

// Board info stored in 2x2
uint4 newBoard (uint posID)
{
    [flatten]
    if (posID == B_LEFT)
    {
        /*
            Binary representation
            The most sigfig bit is the piece color

            0b 0100 0010 0011 0101 0110 0011 0010 0100
            0b 0001 0001 0001 0001 0001 0001 0001 0001
            0b 0000 0000 0000 0000 0000 0000 0000 0000
            0b 0000 0000 0000 0000 0000 0000 0000 0000
        */
        return uint4(0u, 0u, 286331153u, 1110795044u);
    }
    else if (posID == B_RIGHT)
    {
        /*
            0b 0000 0000 0000 0000 0000 0000 0000 0000
            0b 0000 0000 0000 0000 0000 0000 0000 0000
            0b 1001 1001 1001 1001 1001 1001 1001 1001
            0b 1100 1010 1011 1101 1110 1011 1010 1100
        */
        // Make 0,0 the bottom left
        return uint4(3401444268u, 2576980377u, 0u, 0u);
    }
    else if (posID == T_LEFT)
    {
        /*
            Store the position of each piece
            Rw  Nw  Bw  Qw  Kw  Bw  Nw  Rw
            1,1 1,2 1,3 1,4 1,5 1,6 1,7 1,8
            Pw  Pw  Pw  Pw  Pw  Pw  Pw  Pw
            2,1 2,2 2,3 2,4 2,5 2,6 2,7 2,8

            For some stupid reason I made it (y, x)

            // Queen side
            0b 0001 0001 0001 0010 0001 0011 0001 0100
            // King side
            0b 0001 0101 0001 0110 0001 0111 0001 1000
            // Queen pawns
            0b 0010 0001 0010 0010 0010 0011 0010 0100
            // King pawns
            0b 0010 0101 0010 0110 0010 0111 0010 1000
        */
        return uint4(286397204u, 353769240u, 555885348u, 623257384u);
    }
    else if (posID == T_RIGHT)
    {
        /*
            Rb  Nb  Bb  Qb  Kb  Bb  Nb  Rb
            8,1 8,2 8,3 8,4 8,5 8,6 8,7 8,8
            Pb  Pb  Pb  Pb  Pb  Pb  Pb  Pb
            7,1 7,2 7,3 7,4 7,5 7,6 7,7 7,8

            0b 1000 0001 1000 0010 1000 0011 1000 0100
            0b 1000 0101 1000 0110 1000 0111 1000 1000
            0b 0111 0001 0111 0010 0111 0011 0111 0100
            0b 0111 0101 0111 0110 0111 0111 0111 1000
        */
        return uint4(2172814212u, 2240186248u, 1903326068u, 1970698104u);
    }

    return 0u;
}

// Board eval function
// From https://www.chessprogramming.org/Simplified_Evaluation_Function
float eval (uint4 boardTop[2], float lateGame)
{
    // Empty board
    if (all(boardTop[0] == 0) && all(boardTop[1] == 0))
        return FLT_MIN;
    // x for white pieces, y for black pieces
    float2 boardScore = 0.;
    float2 pieceScore = 0.;
    uint buf;
    int2 pos;
    int i = 0;

    // Pawns
    [unroll]
    for (; i <= 24; i += 8) {
        // White
        buf = (boardTop[0][2] >> i) & 0xff;
        pos = int2(buf & 0xf, buf >> 4);
        boardScore.y += getBoardScore(pos - 1, PAWN, WHITE);
        pieceScore.y += (pos.x + pos.y) > 0 ? pieceVal[PAWN] : 0.0;
        buf = (boardTop[0][3] >> i) & 0xff;
        pos = int2(buf & 0xf, buf >> 4);
        boardScore.y += getBoardScore(pos - 1, PAWN, WHITE);
        pieceScore.y += (pos.x + pos.y) > 0 ? pieceVal[PAWN] : 0.0;
        // Black
        buf = (boardTop[1][2] >> i) & 0xff;
        pos = int2(buf & 0xf, buf >> 4);
        boardScore.x += getBoardScore(pos - 1, PAWN, BLACK);
        pieceScore.x += (pos.x + pos.y) > 0 ? pieceVal[PAWN] : 0.0;
        buf = (boardTop[1][3] >> i) & 0xff;
        pos = int2(buf & 0xf, buf >> 4);
        boardScore.x += getBoardScore(pos - 1, PAWN, BLACK);
        pieceScore.x += (pos.x + pos.y) > 0 ? pieceVal[PAWN] : 0.0;
    }

    // Queen side
    [unroll]
    for (i = 0; i < 2; i++) {
        buf = boardTop[1 - i][0];
        // Queen
        pos = int2(buf & 0xf, (buf & 0xf0) >> 4);
        boardScore[i] += getBoardScore(pos - 1, QUEEN, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[QUEEN] : 0.0;
        // Bishop
        pos = int2((buf & 0xf00) >> 8, (buf & 0xf000) >> 12);
        boardScore[i] += getBoardScore(pos - 1, BISHOP, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[BISHOP] : 0.0;
        // Knight
        pos = int2((buf & 0xf0000) >> 16, (buf & 0xf00000) >> 20);
        boardScore[i] += getBoardScore(pos - 1, KNIGHT, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[KNIGHT] : 0.0;
        // Rooks
        pos = int2((buf & 0xf000000) >> 24, (buf & 0xf0000000) >> 28);
        boardScore[i] += getBoardScore(pos - 1, ROOK, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[ROOK] : 0.0;
    }

    // King side
    [unroll]
    for (i = 0; i < 2; i++) {
        buf = boardTop[1 - i][1];
        // Rook
        pos = int2(buf & 0xf, (buf & 0xf0) >> 4);
        boardScore[i] += getBoardScore(pos - 1, ROOK, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[ROOK] : 0.0;
        // Knight
        pos = int2((buf & 0xf00) >> 8, (buf & 0xf000) >> 12);
        boardScore[i] += getBoardScore(pos - 1, KNIGHT, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[KNIGHT] : 0.0;
        // Bishop
        pos = int2((buf & 0xf0000) >> 16, (buf & 0xf00000) >> 20);
        boardScore[i] += getBoardScore(pos - 1, BISHOP, i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[BISHOP] : 0.0;
        // King, 2 scoring tables
        pos = int2((buf & 0xf000000) >> 24, (buf & 0xf0000000) >> 28);
        boardScore[i] += getBoardScore(pos - 1, (lateGame > 0.0 ? KING + 1 : KING), i);
        pieceScore[i] += (pos.x + pos.y) > 0 ? pieceVal[KING] : 0.0;
    }
    return (pieceScore.y - pieceScore.x) + (boardScore.y - boardScore.x);
}

uint getPiece (uint4 boardArray[2], int2 source)
{
    uint srcPiece = boardArray[source.y > 3 ? 0 : 1][source.y > 3 ? source.y - 4 : source.y];
    srcPiece = (srcPiece >> ((7 - source.x) * 4)) & pMask;
    return srcPiece;
}

bool clearPath (uint4 boardArray[2], int2 source, int2 dest, uint3 srcColCapPawn)
{
    int2 d = dest - source;
    int2 inc = sign(d);
    // don't count the edge pieces
    int2 i = source + inc;
    bool hit = false;

    [loop]
    for (; any(i != dest); i += inc) {
        if (all(abs(i - 3.5) > 3.5)) break;
        uint curPos = getPiece(boardArray, i) & kMask;
        hit = curPos > 0 ? true : hit;
    }

    // Check destination
    uint curPos = getPiece(boardArray, i);

    // If it's a pawn, it can't capture where it moves
    [flatten]
    if (srcColCapPawn.z) {
        hit = hit || (curPos & kMask) > 0;
    }
    else {
        hit = hit || ((curPos & kMask) > 0 &&
            (srcColCapPawn.x == (curPos >> 3)));
    }
    
    // For pawns we check if there's a piece before capturing
    if (srcColCapPawn.y == 1) {
        uint destPc = getPiece(boardArray, dest);
        hit = ((destPc & kMask) > 0 && srcColCapPawn.x != (destPc >> 3)) ?
            false : true;
    }

    return !hit;
}

bool validMove (uint4 boardArray[2], int2 source, int2 dest, float2 hasKingMoved)
{

    // Termination conditions
    if (all(source == dest)) return false; // Same place
    if (any(dest < 0 || dest > 7)) return false; // Off board

    bool valid = false;
    uint srcPiece = getPiece(boardArray, source);

    [branch] switch (srcPiece.x & kMask) {
        case (PAWN) : {
            uint capturing = 0;
            bool atStart = ((srcPiece >> 3) == WHITE && source.y == 1) ||
                ((srcPiece >> 3) == BLACK && source.y == 6);

            [loop]
            for (int i = 0; i < 4; i++) {
                if (!atStart && i == 3) break;
                if (all(source + ((srcPiece >> 3) == BLACK ? 
                    pawnListB[i] : pawnListW[i]) == dest)) {
                    valid = true;
                    capturing = i < 2 ? 1 : 0;
                }
            }
            if (valid) {
                srcPiece.x = srcPiece.x >> 3;
                valid = clearPath(boardArray, source, dest, uint3(srcPiece, capturing, 1));
            }
            break;
        }
        case (KNIGHT) : {
            [unroll]
            for (int i = 0; i < 8; i++) {
                valid = all(source + knightList[i] == dest) ? true : valid;
            }
            uint destPiece = getPiece(boardArray, dest);
            valid = ((destPiece & kMask) > 0 &&
                (srcPiece >> 3) == (destPiece >> 3)) ? false : valid;
            break;
        }
        case (BISHOP) : {
            int4 i = 0..xxxx;
            int4 j = 0..xxxx;

            [unroll]
            for (int c = 0; c < 8; c++, i.xy += 1, i.zw -= 1,
                j.xy += int2(-1, 1), j.zw += int2(1, -1)) {
                valid = all(source + i.xy == dest) ? true : valid;
                valid = all(source + i.zw == dest) ? true : valid;
                valid = all(source + j.xy == dest) ? true : valid;
                valid = all(source + j.zw == dest) ? true : valid;
            }
            if (valid) {
                srcPiece.x = srcPiece.x >> 3;
                valid = clearPath(boardArray, source, dest, uint3(srcPiece, 0..xx));
            }
            break;
        }
        case (ROOK) : {
            valid = source.y == dest.y ? true : valid;
            valid = source.x == dest.x ? true : valid;
            if (valid) {
                srcPiece.x = srcPiece.x >> 3;
                valid = clearPath(boardArray, source, dest, uint3(srcPiece, 0..xx));
            }
            break;
        }
        case (QUEEN) : {
            int4 i = 0..xxxx;
            int4 j = 0..xxxx;
            int c = 0;
            [unroll]
            for (; c < 8; c++, i.xy += 1, i.zw -= 1,
                j.xy += int2(-1, 1), j.zw += int2(1, -1)) {
                valid = all(source + i.xy == dest) ? true : valid;
                valid = all(source + i.zw == dest) ? true : valid;
                valid = all(source + j.xy == dest) ? true : valid;
                valid = all(source + j.zw == dest) ? true : valid;
            }
            valid = source.y == dest.y ? true : valid;
            valid = source.x == dest.x ? true : valid;

            if (valid) {
                srcPiece.x = srcPiece.x >> 3;
                valid = clearPath(boardArray, source, dest, uint3(srcPiece, 0..xx));
            }
            break;
        }
        case (KING) : {
            [unroll]
            for (int i = 0; i < 8; i++) {
                valid = all(source + kingList[i] == dest) ? true : valid;
            }
            // Castling
            if (((srcPiece.x >> 3) == WHITE ? hasKingMoved.x : hasKingMoved.y) < 1.0) {
                valid = (abs(source.x - dest.x) <= 2 && (source.y == dest.y)) ?
                    true : valid;
            }
            if (valid) {
                srcPiece.x = srcPiece.x >> 3;
                valid = clearPath(boardArray, source, dest, uint3(srcPiece, 0..xx));
            }
            break;
        }
    }

    return valid;
}

/*
    posID = Corner ID, which are the UVs
    srcPieceID.x = Piece ID
    srcPieceID.y = pID table index to determine how much to shift by
                   in the packed bits
*/

uint4 doMoveNoCheck(in uint4 boardPosArray[4], in uint posID, in uint2 srcPieceID,
    in int2 source, in int2 dest, int debug)
{

    uint4 boardArray[2] = { boardPosArray[B_LEFT], boardPosArray[B_RIGHT] };
    uint colP = srcPieceID.x >> 3;

    [branch]
    if (posID < 2) {
        uint srcMask = pMask << ((7 - source.x) * 4);
        uint destPiece = srcPieceID.x;
        // Queen me
        if ((srcPieceID.x & kMask) == PAWN &&
            ((dest.y == 0 && colP == BLACK) || (dest.y == 7 && colP == WHITE))) {
            // Due to the limitations of my chess board implementation
            // I have to look for a piece that's not captured
            [loop]
            for (int i = 5; i >= 2; i--) {
                uint2 checkPc[2] = searchID[i];
                uint buff = ((boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[0].x]) >> checkPc[0].y) & 0xff;

                // Captured piece
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    destPiece = i;
                    break;
                }
                buff = ((boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[1].x]) >> checkPc[1].y) & 0xff;
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    destPiece = i;
                    break;
                }
            }
        }
        
        // Castling, compacted
        if ((srcPieceID.x & kMask) == KING && abs(dest.x - source.x) == 2) {

            uint4 ind;
            // Array indicies for different sides
            ind = colP == WHITE ?
                int4(T_LEFT, dest.x == 6 ? 1 : 0, B_RIGHT, 0) : 
                int4(T_RIGHT, dest.x == 6 ? 1 : 0, B_LEFT, 3) ;

            // Find the rook
            uint buff = boardPosArray[ind.x][ind.y] >> (dest.x == 6 ? 0 : 24);
            uint2 rook = uint2((buff >> 4) & 0xf, buff & 0xf) - 1;
            
            uint3 ind2; 
            // Check the spaces between king and rook are empty 
            ind2.x = dest.x == 6 ? 0xf0 : 0xff00000;    
            ind2.y = (boardPosArray[ind.z][ind.w] & ind2.x) == 0;

            ind2.z = all(rook == uint2(colP == WHITE ? 0 : 7,
                dest.x == 6 ? 7 : 0));

            // Masks to insert/delete rook
            uint2 masks;
            masks.x = dest.x == 6 ? ~0xf : ~0xf0000000;
            masks.y = colP == WHITE ?
                        dest.x == 6 ? 0xc00 : 0xc0000 :
                        dest.x == 6 ? 0x400 : 0x40000 ;

            // If theres no obstruction, and the rook is preset
            [flatten]
            if (ind2.y && ind2.z) {
                // Compiler complaining about l-values fix
                [flatten]
                if (ind.w == 0)
                {
                    // Delete rook
                    boardPosArray[ind.z][0] &= masks.x;
                    // Insert rook in new spot
                    boardPosArray[ind.z][0] |= masks.y;
                }
                else {
                    boardPosArray[ind.z][3] &= masks.x;
                    boardPosArray[ind.z][3] |= masks.y;
                }
            }
            else return 0;
        }

        destPiece |= colP << 3;
        destPiece = destPiece << ((7 - dest.x) * 4);

        // Remove piece from source position
        uint2 srcXY;
        srcXY.x = source.y > 3 ? B_LEFT : B_RIGHT;
        srcXY.y = source.y > 3 ? source.y - 4 : source.y;
        // Compiler complaining about l-values fix
        [flatten]
        if (srcXY.y == 0) boardPosArray[srcXY.x][0] &= ~srcMask;
        else if (srcXY.y == 1) boardPosArray[srcXY.x][1] &= ~srcMask;
        else if (srcXY.y == 2) boardPosArray[srcXY.x][2] &= ~srcMask;
        else if (srcXY.y == 3) boardPosArray[srcXY.x][3] &= ~srcMask;

        // Place piece in destination
        uint2 destXY;
        destXY.x = dest.y > 3 ? B_LEFT : B_RIGHT;
        destXY.y = dest.y > 3 ? dest.y - 4 : dest.y;

        uint destMask = pMask << ((7 - dest.x) * 4);
        // Compiler complaining about l-values fix
        [flatten]
        if (destXY.y == 0)
        {
            boardPosArray[destXY.x][0] &= ~destMask;
            boardPosArray[destXY.x][0] |= destPiece;
        }
        else if (destXY.y == 1)
        {
            boardPosArray[destXY.x][1] &= ~destMask;
            boardPosArray[destXY.x][1] |= destPiece;
        }
        else if (destXY.y == 2)
        {
            boardPosArray[destXY.x][2] &= ~destMask;
            boardPosArray[destXY.x][2] |= destPiece;
        }
        else if (destXY.y == 3)
        {
            boardPosArray[destXY.x][3] &= ~destMask;
            boardPosArray[destXY.x][3] |= destPiece;
        }

        return posID == B_LEFT ? boardPosArray[B_LEFT] : boardPosArray[B_RIGHT];
    }
    // Bottom pixels containing chess piece positions
    else {
        // Replace destination
        uint destPc = getPiece(boardArray, dest);
        uint destX = (destPc >> 3) == WHITE ? T_LEFT : T_RIGHT;
        uint2 destY[2] = searchID[destPc & kMask];

        // If its a pawn, find which pawn it is
        [branch]
        if ((destPc & kMask) == 0) { /* Nothing! */ }
        else if ((destPc & kMask) == PAWN) {
            [unroll]
            for (int k = 2; k <= 3; k++) {
                [unroll]
                for (int j = 0; j < 32; j += 8) {
                    uint pos = 0xff & (boardPosArray[destX][k] >> j);
                    if (all(int2(pos & 0xf, pos >> 4) == (dest + 1))) {
                        uint destMask = 0xff << j;
                        // Compiler complaining about l-values fix
                        [flatten]
                        if (k == 2) { boardPosArray[destX][2] &= ~destMask; }
                        else { boardPosArray[destX][3] &= ~destMask; }
                    }
                }
            }
        }
        else {
            [unroll]
            for (int i = 0; i <= 1; i++) {
                uint pos = (boardPosArray[destX][destY[i].x] >>
                    destY[i].y) & 0xff;
                // y, x format flipped
                if (all(int2(pos & 0xf, pos >> 4) == dest + 1)) {
                    uint destMask = 0xff << destY[i].y;
                    // Compiler complaining about l-values fix
                    [flatten]
                    if (destY[i].x == 0) boardPosArray[destX][0] &= ~destMask;
                    else if (destY[i].x == 1) boardPosArray[destX][1] &= ~destMask;
                    else if (destY[i].x == 2) boardPosArray[destX][2] &= ~destMask;
                    else if (destY[i].x == 3) boardPosArray[destX][3] &= ~destMask;
                }
            }
        }

        uint2 srcXY;
        srcXY.x = srcPieceID.x >> 3 == WHITE ? T_LEFT : T_RIGHT;
        srcXY.y = floor(pID[srcPieceID.y] / 100);

        // Zero out
        uint off = (pID[srcPieceID.y] - srcXY.y * 100);
        uint srcMask = 0xff << off;
        srcMask = ~srcMask;
        // Compiler complaining about l-values fix
        [flatten]
        if (srcXY.y == 0) boardPosArray[srcXY.x][0] &= srcMask;
        else if (srcXY.y == 1) boardPosArray[srcXY.x][1] &= srcMask;
        else if (srcXY.y == 2) boardPosArray[srcXY.x][2] &= srcMask;
        else if (srcXY.y == 3) boardPosArray[srcXY.x][3] &= srcMask;

        // Queen me
        [branch]
        if ((srcPieceID.x & kMask) == PAWN &&
            ((dest.y == 0 && colP == BLACK) || (dest.y == 7 && colP == WHITE))) {
            // Due to the limitations of my chess board implementation
            // I have to look for a piece that's not captured
            [loop]
            for (int i = 5; i >= 2; i--) {
                uint2 checkPc[2] = searchID[i];
                uint buff = ((boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[0].x]) >> checkPc[0].y) & 0xff;
                // Captured piece
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    srcXY.x = colP == WHITE ? T_LEFT : T_RIGHT;
                    srcXY.y = checkPc[0].x;
                    off = checkPc[0].y;
                    break;
                }

                buff = ((boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[1].x]) >> checkPc[1].y) & 0xff;
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    srcXY.x = colP == WHITE ? T_LEFT : T_RIGHT;
                    srcXY.y = checkPc[1].x;
                    off = checkPc[1].y;
                    break;
                }
            }
        }

        // Castling, compacted
        if ((srcPieceID.x & kMask) == KING && abs(dest.x - source.x) == 2) {

            uint4 ind;
            // Array indicies for different sides
            ind = colP == WHITE ?
                int4(T_LEFT, dest.x == 6 ? 1 : 0, B_RIGHT, 0) : 
                int4(T_RIGHT, dest.x == 6 ? 1 : 0, B_LEFT, 3) ;

            // Find the rook
            uint buff = (boardPosArray[ind.x][ind.y]) >> (dest.x == 6 ? 0 : 24);
            uint2 rook = uint2((buff >> 4) & 0xf, buff & 0xf) - 1;

            uint3 ind2; 
            // Check the spaces between king and rook are empty 
            ind2.x = dest.x == 6 ? 0xf0 : 0xff00000;    
            ind2.y = (boardPosArray[ind.z][ind.w] & ind2.x) == 0;
            ind2.z = all(rook == uint2(colP == WHITE ? 0 : 7,
                dest.x == 6 ? 7 : 0));

            // Masks to insert/delete rook
            uint2 masks;
            masks.x = dest.x == 6 ? ~0xff : ~0xff000000;
            masks.y = colP == WHITE ?
                        dest.x == 6 ? 0x16 : 0x14000000 :
                        dest.x == 6 ? 0x86 : 0x84000000 ;

            // If theres no obstruction, and the rook is present
            [flatten]
            if (ind2.y && ind2.z) {
                // Compiler complaining about l-values fix
                [flatten]
                if (ind.y == 0)
                {
                    // Delete rook
                    boardPosArray[ind.x][0] &= masks.x;
                    // Insert rook in new spot
                    boardPosArray[ind.x][0] |= masks.y;
                }
                else {
                    boardPosArray[ind.x][1] &= masks.x;
                    boardPosArray[ind.x][1] |= masks.y;
                }
            }
            else return 0;
        }

        // New position
        dest = dest + 1;
        uint newPos = (((dest.y & pMask) << 4) | (dest.x & pMask)) << off;
        // Compiler complaining about l-values fix
        [flatten]
        if (srcXY.y == 0) boardPosArray[srcXY.x][0] |= newPos;
        else if (srcXY.y == 1) boardPosArray[srcXY.x][1] |= newPos;
        else if (srcXY.y == 2) boardPosArray[srcXY.x][2] |= newPos;
        else if (srcXY.y == 3) boardPosArray[srcXY.x][3] |= newPos;

        return posID == T_LEFT ? boardPosArray[T_LEFT] : boardPosArray[T_RIGHT];
    }
}

/*
    Adds a valid destination check on doMoveNoCheck()
*/
uint4 doMove(in uint4 boardPosArray[4], in uint posID, in uint2 srcPieceID,
    in int2 source, in int2 dest, in float2 hasKingMoved)
{
    uint4 boardArray[2] = { boardPosArray[B_LEFT], boardPosArray[B_RIGHT] };
    bool valid = validMove(boardArray, source, dest, hasKingMoved);
    if (!valid) return 0;
    return doMoveNoCheck(boardPosArray, posID, srcPieceID, source, dest, 0);
}

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
        dest = 0;
    }
    // Rooks
    else if (idx_t < moveNum[ROOK].y)
    // King side rooks don't shift
    {
        idx_t -= moveNum[BISHOP].y;
        srcPieceID = uint2(ROOK,
            (idx_t < (uint(moveNum[ROOK].x * 0.5))) ? 0 : 7);
        dest = 0;
    }
    // Queen
    // Kings/Queens don't need shifts srcPieceID.y shifts
    else if (idx_t < moveNum[QUEEN].y)
    {
        srcPieceID = uint2(QUEEN, 3);
        dest = 0;
    }
    // King
    else if (idx_t < moveNum[KING].y)
    {
        idx_t -= moveNum[QUEEN].y;
        srcPieceID = uint2(KING, 4);
        dest = kingList[idx_t];
    }
    else
    {
        srcPieceID = 0;
        dest = -1000;
    }
    srcPieceID.x |= (turn << 3);

    // Find the source position
    uint shift = pID[srcPieceID.y] -
        (floor(pID[srcPieceID.y] / 100) * 100);
    uint buff = ((boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
        [floor(pID[srcPieceID.y] / 100)]) >> shift) & 0xff;
    
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
        uint idMod = idx_t % (moveNum[ROOK].x / 2);
        uint r = moveNum[ROOK].x / 4;
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
            idx_t -= uint(moveNum[ROOK].x * 0.5);
            int4 bOrigin = getBishopOrigin(src);
            // Different moves on white/black tiles
            bool onBlack = (src.x % 2 == src.y % 2);
            dest = idx_t < (onBlack ? 7 : 8) ?
                bOrigin.xy + int2(-1, 1) * idx_t :
                bOrigin.zw + int2(1, 1) * (idx_t - (onBlack ? 7 : 8));
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

// Since there's no space to save the ID of the piece the computer
// moved, find the difference between two boards to highlight
float2 findComputerDest(in uint4 boardHistory[2])
{
    int3 ind = -1;
    // XOR the boards to find where it changed
    [unroll]
    for (int i = 0; i < 4; i++) {
        ind.x = ((boardHistory[0][i] ^ boardHistory[1][i]) > 0) ? i : ind.x;
    }
    if (ind.x < 0) return ind.yz;
    uint2 buff;
    [unroll]
    for (int j = 0; j < 4; j++) {
        buff.x = ((boardHistory[0][ind.x]) >> (j * 8)) & 0xff;
        buff.y = ((boardHistory[1][ind.x]) >> (j * 8)) & 0xff;
        ind.yz = ((buff.x ^ buff.y) > 0) ?
            float2(buff.y & 0xf, buff.y >> 4) - 1.0 : ind.yz;
    }
    return ind.yz;
}

#endif