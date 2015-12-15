#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "def.h"

uint32_t bit_invert(uint32_t a) {
  uint32_t result = 0;
  uint32_t temp;
  int flag; // 0 or 1;
  int nflag; // 反転させたもの
  int i;
  for (i = 0; i < 32; i++) {
    temp = a >> (31 - i);
    flag = temp & 1;
    nflag = 1 - flag;
    result = result + (nflag << (31 - i));
  }
  return (result);
}


uint32_t ftoi(uint32_t a) {
  union data_32bit a_32bit;
  uint32_t result;
  int flag;  // 正なら0,負なら1
  int diff;
  int nbit;  // 指数部の上位nビット(diff < 23 なら n=diff, diff >= 23ならn=23)
  int n;     // 上のn

  a_32bit.uint32 = a;
  flag = a_32bit.sign; 
  if (a_32bit.exp < 127) {
    result = 0;
  } else {
    diff = a_32bit.exp - 127;
    if (diff > 30) {
      if (flag == 0) {
	result = INT_MAX;
      } else {
	result = NINT_MAX;
      }
    } else {
      if (diff < 23) {
	n = diff;
	nbit = a_32bit.frac >> (23 - n);
      } else {
	n = 23;
	nbit = a_32bit.frac;
      }
      result = (1 << diff) + (nbit << (diff - n));
    }
    if (flag == 1) {
      result = bit_invert(result) + 1;    
    }
  }
  return (result);
}
