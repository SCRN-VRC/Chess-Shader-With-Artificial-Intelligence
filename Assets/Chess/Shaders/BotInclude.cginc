#ifndef _BOT_INCLUDE
#define _BOT_INCLUDE

            RWStructuredBuffer<float4> buffer : register(u1);

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

// Pieces mask
static const uint pMask = 0xf;

// B\W side mask
static const uint sMask = 0x8;

// Piece w\o side mask
static const uint kMask = 0x7;

// Piece values

static const float pieceVal[7] =
{
    0, 100, 320, 330, 500, 900, 20000
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
    8,1,1,8, 8,2,1,7, 8,3,1,6, 8,4,1,5, 8,5,1,4, 8,6,1,3, 8,7,1,2, 8,8,1,1,
    7,1,1,7, 8,1,1,6, 8,2,1,5, 8,3,1,4, 8,4,1,3, 8,6,1,2, 8,6,1,1, 8,7,2,1,
    6,1,1,6, 7,1,1,5, 8,1,1,4, 8,2,1,3, 8,3,1,2, 8,4,1,1, 8,5,2,1, 8,6,3,1,
    5,1,1,5, 6,1,1,4, 7,1,1,3, 8,1,1,2, 8,2,1,1, 8,3,2,1, 8,4,3,1, 8,5,4,1,
    4,1,1,4, 5,1,1,3, 6,1,1,2, 7,1,1,1, 8,1,2,1, 8,2,3,1, 8,3,4,1, 8,4,5,1,
    3,1,1,3, 4,1,1,2, 5,1,1,1, 6,1,2,1, 7,1,3,1, 8,1,4,1, 8,2,5,1, 8,3,6,1,
    2,1,1,2, 3,1,1,1, 4,1,2,1, 5,1,3,1, 6,1,4,1, 7,1,5,1, 8,1,6,1, 8,2,7,1,
    1,1,1,1, 2,1,2,1, 3,1,3,1, 4,1,4,1, 5,1,5,1, 6,1,6,1, 7,1,7,1, 8,1,8,1
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
     5, 10, 10,-20,-20, 10, 10,  5,
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
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5, 10, 10,  5,  0,-10,
    -10,  5,  5, 10, 10,  5,  5,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10, 10, 10, 10, 10, 10, 10,-10,
    -10,  5,  0,  0,  0,  0,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20,

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

// List of moves
static const int2 pawnListW[4] = { -1, 1, 1, 1, 0, 1, 0, 2 };
static const int2 pawnListB[4] = { -1, -1, 1, -1, 0, -1, 0, -2 };
static const int2 knightList[8] = { -1, 2, -2, 1, -2, -1, -1, -2, 1,
    -2, 2, -1, 2, 1, 1, 2 };
static const int2 kingList[8] = { 0, 1, 1, 1, 1, 0, 1, -1,
    0, -1, -1, -1, -1, 0, -1, 1 };

// Board info stored in 2x2
uint4 newBoard (uint posID)
{
    uint4 uOut = 0;
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
        uOut = uint4(0, 0, 4369, 16949);
        uOut = (uOut << 16) | uint4(0, 0, 4369, 25380);
        //return uint4(0, 0, 286331153, 1110795044);
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
        uOut = uint4(51901, 39321, 0, 0);
        uOut = (uOut << 16) | uint4(60332, 39321, 0, 0);
        //return uint4(3401444268, 2576980377, 0, 0);
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
        uOut = uint4(4370, 5398, 8482, 9510);
        uOut = (uOut << 16) | uint4(4884, 5912, 8996, 10024);
        //return uint4(286397204, 353769240, 555885348, 623257384);
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
        uOut = uint4(33154, 34182, 29042, 30070);
        uOut = (uOut << 16) | uint4(33668, 34696, 29556, 30584);
        //return uint4(2172814212, 2240186248, 1903326068, 1970698104);
    }

    return uOut;
}

// Board eval function
// Also from https://www.chessprogramming.org/Simplified_Evaluation_Function
float eval (uint4 boardArray[2], bool lateGame)
{

    float boardScore = 0.;
    float pieceScore = 0.;

    [unroll]
    for (int i = 0; i < 4; i++) {
        [unroll]
        for (int j = 0; j < 8; j++) {
            uint2 pieces;
            pieces.x = boardArray[0][i] & pMask;
            pieces.y = boardArray[1][i] & pMask;

            // black pieces are negative
            float2 bw;
            bw.x = (pieces.x & sMask) >> 3 > 0. ? 1. : -1.;
            bw.y = (pieces.y & sMask) >> 3 > 0. ? 1. : -1.;

            // individual piece values
            pieceScore += bw.x * pieceVal[pieces.x & kMask];
            pieceScore += bw.y * pieceVal[pieces.y & kMask];

            // late game king changes table
            /*
                Additionally we should define where the ending begins.
                For [chessprogramming.org] it might be either if:

                Both sides have no queens or
                Every side which has a queen has additionally no
                other pieces or one minor piece maximum.
            */
            uint2 kingTbl;
            kingTbl.x = lateGame && (pieces.x & kMask) == KING ? 1 : 0;
            kingTbl.y = lateGame && (pieces.y & kMask) == KING ? 1 : 0;

            // piece-square table, black is flipped
            boardScore += bw.x * pcTbl[(pieces.x & kMask) + kingTbl.x]
                [bw.x > 0 ? i + 4 : 3 - i][j];
            boardScore += bw.y * pcTbl[(pieces.y & kMask) + kingTbl.y]
                [bw.y > 0 ? i : 7 - i][j];

            boardArray[0][i] = boardArray[0][i] << 4;
            boardArray[1][i] = boardArray[1][i] << 4;
        }
    }

    return pieceScore + boardScore;
}

uint getPiece (uint4 boardArray[2], int2 source)
{
    uint srcPiece = boardArray[source.y > 3 ? 0 : 1][source.y > 3 ? source.y - 4 : source.y];
    srcPiece = (srcPiece >> (7 - source.x) * 4) & pMask;
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

bool validMove (uint4 boardArray[2], int2 source, int2 dest)
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
            valid = (destPiece & kMask > 0 &&
                srcPiece >> 3 == destPiece >> 3) ? false : valid;
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
            [unroll]
            for (int i = 0; i < 8; i++) {
                valid = all(int2(i, source.y) == dest) ? true : valid;
                valid = all(int2(source.x, i) == dest) ? true : valid;
            }
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
            [unroll]
            for (c = 0; c < 8; c++) {
                valid = all(int2(c, source.y) == dest) ? true : valid;
                valid = all(int2(source.x, c) == dest) ? true : valid;
            }
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
*/
uint4 doMove(in uint4 boardPosArray[4], in uint posID, in uint2 srcPieceID,
    in int2 source, in int2 dest)
{

    uint4 boardArray[2] = { boardPosArray[B_LEFT], boardPosArray[B_RIGHT] };
    bool valid = validMove(boardArray, source, dest);
    if (!valid) return 0;

    // Top pixels containing chess board
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
                uint buff = (boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[0].x] >> checkPc[0].y) & 0xff;

                // Captured piece
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    destPiece = i;
                    break;
                }
                buff = (boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[1].x] >> checkPc[1].y) & 0xff;
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    destPiece = i;
                    break;
                }
            }
        }
        
        // Castling, compacted
        if ((srcPieceID.x & kMask) == KING && all(source ==
            int2(4, colP == WHITE ? 0 : 7))) {

            uint4 ind;
            // Array indicies for different sides
            ind = colP == WHITE ?
                int4(T_LEFT, dest.x == 5 ? 1 : 0, B_RIGHT, 0) : 
                int4(T_RIGHT, dest.x == 5 ? 1 : 0, B_LEFT, 3) ;

            uint3 ind2;
            // Check the spaces between king and rook are empty
            ind2.x = dest.x == 5 ? 0xf0 : 0xff00000;
            ind2.y = (boardPosArray[ind.z][ind.w] & ind2.x) == 0;

            // Find the rook
            uint buff = boardPosArray[ind.x][ind.y] >> (dest.x == 5 ? 0 : 24);
            uint2 rook = uint2((buff >> 4) & 0xf, buff & 0xf) - 1;

            ind2.z = all(rook == uint2(colP == WHITE ? 0 : 7,
                dest.x == 5 ? 7 : 0));

            // Masks to insert/delete rook
            uint2 masks;
            masks.x = dest.x == 5 ? ~0xf : ~0xf0000000;
            masks.y = colP == WHITE ?
                        dest.x == 5 ? 0xc00 : 0xc0000 :
                        dest.x == 5 ? 0x400 : 0x40000 ;

            // If theres no obstruction, and the rook is preset
            [flatten]
            if (ind2.y && ind2.z) {
                // Move king extra step
                dest.x += dest.x == 5 ? 1 : -1;
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
        uint destX = destPc >> 3 == WHITE ? T_LEFT : T_RIGHT;
        uint2 destY[2] = searchID[destPc & kMask];
        
        // If its a pawn, find which pawn it is
        [branch]
        if ((destPc & kMask) == 0) { /* Nothing! */ }
        else if ((destPc & kMask) == PAWN) {
            [unroll]
            for (int k = 2; k <= 3; k++) {
                //int j = 24;
                [unroll]
                for (int j = 0; j < 32; j += 8) {
                    uint pos = 0xff & (boardPosArray[destX][k] >> j);
                    if (all(int2(pos & 0xf, pos >> 4) == dest + 1)) {
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
                uint buff = (boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[0].x] >> checkPc[0].y) & 0xff;
                // Captured piece
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    srcXY.x = colP == WHITE ? T_LEFT : T_RIGHT;
                    srcXY.y = checkPc[0].x;
                    off = checkPc[0].y;
                    break;
                }

                buff = (boardPosArray[colP == WHITE ? T_LEFT : T_RIGHT]
                    [checkPc[1].x] >> checkPc[1].y) & 0xff;
                if (dot(uint2(buff >> 4, buff & 0xf), 1..xx) == 0) {
                    srcXY.x = colP == WHITE ? T_LEFT : T_RIGHT;
                    srcXY.y = checkPc[1].x;
                    off = checkPc[1].y;
                    break;
                }
            }
        }

        // Castling, compacted
        if ((srcPieceID.x & kMask) == KING && all(source ==
            int2(4, colP == WHITE ? 0 : 7))) {

            uint4 ind;
            // Array indicies for different sides
            ind = colP == WHITE ?
                int4(T_LEFT, dest.x == 5 ? 1 : 0, B_RIGHT, 0) : 
                int4(T_RIGHT, dest.x == 5 ? 1 : 0, B_LEFT, 3) ;

            uint3 ind2;
            // Check the spaces between king and rook are empty
            ind2.x = dest.x == 5 ? 0xf0 : 0xff00000;
            ind2.y = (boardPosArray[ind.z][ind.w] & ind2.x) == 0;

            // Find the rook
            uint buff = boardPosArray[ind.x][ind.y] >> (dest.x == 5 ? 0 : 24);
            uint2 rook = uint2((buff >> 4) & 0xf, buff & 0xf) - 1;

            ind2.z = all(rook == uint2(colP == WHITE ? 0 : 7,
                dest.x == 5 ? 7 : 0));

            // Masks to insert/delete rook
            uint2 masks;
            masks.x = dest.x == 5 ? ~0xff : ~0xff000000;
            masks.y = colP == WHITE ?
                        dest.x == 5 ? 0x16 : 0x14000000 :
                        dest.x == 5 ? 0x86 : 0x84000000 ;

            // If theres no obstruction, and the rook is present
            [flatten]
            if (ind2.y && ind2.z) {
                // Move king extra step
                dest.x += dest.x == 5 ? 1 : -1;
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
        }

        // New position
        dest = dest + 1;
        uint newPos = ((dest.y & pMask) << 4 | (dest.x & pMask)) << off;
        // Compiler complaining about l-values fix
        [flatten]
        if (srcXY.y == 0) boardPosArray[srcXY.x][0] |= newPos;
        else if (srcXY.y == 1) boardPosArray[srcXY.x][1] |= newPos;
        else if (srcXY.y == 2) boardPosArray[srcXY.x][2] |= newPos;
        else if (srcXY.y == 3) boardPosArray[srcXY.x][3] |= newPos;

        return posID == T_LEFT ? boardPosArray[T_LEFT] : boardPosArray[T_RIGHT];
    }

}

#endif