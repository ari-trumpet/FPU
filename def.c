#include "def.h"

// 下からnbitのORをとる 返り値0or1 
int or_nbit(unsigned int num, int n) {
  unsigned int all = (1 << n) - 1;
  unsigned int result = num & all;
  if (result > 0) 
    return 1;
  else
    return 0;
}

//最近接偶数への丸め(round to the nearest even) -- 注：27bit -> 24bit
unsigned int round_even(unsigned int num) {
  int right4;
  right4 = num & 15;
  if ((4 < right4 && right4 < 8) || 11 < right4) 
    num = (num >> 3) + 1;
  else
    num = num >> 3;
  return (num);
}

//最近接偶数丸めにより仮数部がオーバーフローしてしまうときに'1'を返す。 注意: 27bit
//"111111111111111111111111100" ～ "111111111111111111111111111" のとき。
int round_even_carry(unsigned int num) {
  if (0x7fffffcu <= num && num <= 0x7ffffffu)
    return 1;
  else
    return 0;
}

//  num[31]...num[0] について　num[left]...num[right] を切り取る
unsigned int cut_uint32(unsigned int num, int left,int right){
  unsigned int d = (((1u << (left + 1)) - 1) & num) >> right;
  return d;
}
