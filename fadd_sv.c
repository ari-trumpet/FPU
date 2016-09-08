#include <stdio.h>
#include <stdint.h>

#define SIGN(x)         (x & (1u << 31))
#define EXP(x)          (((x) >> 23) & 0xff)
#define MAN(x)          ((x) & 0x7fffff)
#define RANGE(x, a, b)  (((x) >> (a)) & ((1u << (b - a)) - 1u))
#define ISNaN(x)        (EXP(x) == 0xff && MAN(x) != 0)
#define ISINF(x)        (SIGN(x) == 0 && EXP(x) == 0xff && MAN(x) == 0)
#define ISNINF(x)       (SIGN(x) == 1 << 31 && EXP(x) == 0xff && MAN(x) == 0)

uint32_t fadd(uint32_t a, uint32_t b)
{
    uint32_t i;

    if (ISNaN(a) || ISNaN(b)){
      return 0x7fffffff;                // nan
    }
    else if ( (ISINF(a) && ISNINF(b)) || (ISNINF(a) && ISINF(b))){
      return 0x7fffffff;                // nan
    }
    else if (ISINF(a) || ISINF(b)){
      return 0x7f800000;                // inf
    }
    else if (ISNINF(a) || ISNINF(b)){
      return 0xff800000;                // ninf
    }
    else if (EXP(a) == 0 && EXP(b) == 0){
      return 0x00000000;
    }
    else if (EXP(a) == 0 || EXP(b) == 0){
      return (EXP(a) == 0) ? b : a;
    }

    if (RANGE(a, 0, 31) < RANGE(b, 0, 31)) {
        uint32_t t = a; a = b; b = t;
    }


    uint32_t sign = SIGN(a);
    uint32_t exp  = EXP(a);


    if (EXP(a) - EXP(b) > 26) return a;			//returncase0


    uint32_t ma = (1 << 26) | (MAN(a) << 3);
    uint32_t mb = (1 << 26) | (MAN(b) << 3);


    for (i = 0; i < EXP(a) - EXP(b); ++i)
        mb = (mb >> 1) | (mb & 1);
    
    
    if (SIGN(a) == SIGN(b)) {									
        ma += mb;
        if (RANGE(ma, 27, 28) == 1) {
            ++exp;					// expplus
            ma = (ma >> 1) | (ma & 1);
        }
    } else {
        ma -= mb;
        if (ma == 0) return 0;				// returncase1
        while (RANGE(ma, 26, 27) == 0) {
           // if (exp == 0) return 0u; 
            --exp;					// expminus
            if (exp == 0) return 0u; // sign;   // returncase2  // nzeroは返さない
            //--exp;
            ma <<= 1;					// maminusshift
        }
    }


    if ((ma & 4) && (ma & 11)) {
        ma += (1 << 3);
        if (RANGE(ma, 27, 28) == 1) {
            ++exp;
            ma >>= 1;
        }
    }


    if (exp == 255) return sign | 0x7f800000;
    if (exp ==   0) return sign;

    return sign | (exp << 23) | RANGE(ma, 3, 26);
}
