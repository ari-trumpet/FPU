#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#ifndef DEF_H
#define DEF_H

#define FRAC_MAX 8388607 // 23bit all 1
#define ZERO     0u
#define NZERO    2147483648u
#define INF      2139095040u
#define NINF     4286578688u
#define MY_NAN      2147483647u
#define NNAN     4290772992u
#define INT_MAX  2147483647u
#define NINT_MAX 2147483648u


union data_32bit {
  struct {
    unsigned int frac : 23;
    unsigned int exp  : 8;
    unsigned int sign : 1;
  };
  float fl32;
  uint32_t uint32;
};


// 下からnbitのORをとる 返り値0or1 
int or_nbit(unsigned int num, int n);

//最近接偶数への丸め(round to the nearest even) -- 注：27bit -> 24bit
unsigned int round_even(unsigned int num);

//最近接偶数丸めにより仮数部がオーバーフローしてしまうときに'1'を返す。 注意: 27bit
//"111111111111111111111111100" ～ "111111111111111111111111111" のとき。
int round_even_carry(unsigned int num);

#endif
