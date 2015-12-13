/* コンパイル時　gcc fsqrt.c -lm */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include "def.h"

#define MAX      512  // 1 ~ 2, 2 ~ 4 をそれぞれ512分割(計1024分割)
#define MASK9    8372224 //((1 << 9) - 1) << 14 精度を変更する場合注意
#define MASK10   8380416 //((1 << 10) - 1) << 13  精度を変更する場合注意

uint32_t fadd(uint32_t a, uint32_t b);

uint32_t fmul(uint32_t a, uint32_t b);

static double make_a(double t, double c) {
  double a;
  a = 1 / (sqrt(t+c) + sqrt(t));
  return a;
}

static double make_b(double t, double c) {
  double b, temp;
  temp = (2 * make_a(t,c) * sqrt(t)) - 1;
  b = (2 - temp * temp) / (8 * make_a(t,c));
  return b;
}

uint32_t fsqrt(uint32_t org) {
  double a_db, b_db, c, t;
  union data_32bit a, b, x, result, original, temp;
  int d;
  unsigned int index; //どのグループに属するかを示す値(1<x<4を0~2^10-1に割り当てる)
  
  original.uint32 = org;
  if (original.sign == 1) {
    if (original.exp == 0) {
      result.uint32 = NZERO;  // -0 -> -0 (非正規化数も含む)
    } else {
      result.uint32 = NNAN;   // 負の数 -> -nan
    }
  } else if (original.exp == 0) {
    result.uint32 = ZERO;  // 0 -> 0 (非正規化数も含む)
  } else if (original.exp == 255 && original.frac != 0) {
    result.uint32 = MY_NAN; // nan -> nan
  } else if (original.uint32 == INF) {
    result.uint32 = INF;    // inf -> inf ??
  } else {

    result.sign = 0;
    x.uint32 = original.uint32;
    
    index = (x.frac & MASK9) >> 14;
    if ((x.exp & 1) == 0) {  // 2の奇数乗の場合 ※exp-127
      c = 2.0 / MAX;
      t = 2.0 + c * index;
      index += (1 << 9);  //この３つの順番重要
    } else {
      c = 1.0 / MAX;
      t = 1.0 + c * index;
    }
              
    if (original.exp >= 127) {
      d = original.exp - 127;
    } else {
      d = 127 - original.exp;
    }
    
    if ((d & 1) == 0) {
      x.exp = 127;
    } else {
      x.exp = 128; // 奇数乗のとき(1.仮数部)*2 
    }

    if (original.exp >= 127) {
      d = d >> 1;
      result.exp = 127 + d;
    } else {
      d = (d + 1) >> 1;
      result.exp = 127 - d;
    }

    // ここから先はtableから持ってくる部分
    a_db = make_a(t,c);
    b_db = make_b(t,c);
    a.fl32 = (float)a_db;
    b.fl32 = (float)b_db;
    // ここまで
    
    temp.uint32 = fadd(fmul(a.uint32, x.uint32), b.uint32);
    result.frac = temp.frac;
  }
  return (result.uint32);
}
