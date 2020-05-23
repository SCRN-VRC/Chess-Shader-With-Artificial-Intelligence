#ifndef _LAYOUT
#define _LAYOUT

#define txCurBoardBL       int2(0, 510)
#define txCurBoardBR       int2(1, 510)
#define txCurBoardTL       int2(0, 511)
#define txCurBoardTR       int2(1, 511)

// x, y dimensions of set of board group generated per board
// z, w dimensions of all boards combined
#define boardParams        float4(300, 2, 300, 300)

// Move count table for branching
static const uint2 moveNum[7] =
{
    // Total    Cumulative
    0,          0,      // Nothing
    32,         32,     // Pawns
    16,         48,     // Knights
    30,         78,     // Bishops
    32,         110,    // Rooks
    31,         141,    // Queen
    9,          150     // King
};

float4 LoadValue( in Texture2D<float4> tex, in int2 re )
{
    return tex.Load(int3(re, 0));
}

void StoreValue( in int2 txPos, in float4 value, inout float4 col, in int2 fragPos )
{
    col = all(fragPos == txPos) ? value : col;
}

#endif