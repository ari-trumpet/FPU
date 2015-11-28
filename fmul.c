#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "def.h"

uint32_t fmul(uint32_t a, uint32_t b) {

  union data_32bit a_32bit, b_32bit, result;
  long long int a_mant, b_mant;
  long long int a_hmant, a_lmant, b_hmant, b_lmant;
  long long int product; //仮数部の積
  int s_bit;   //sticky bit
  int exp;     //場合によっては途中で255を上回ることがあるので、最後にresult.expに代入する


  a_32bit.uint32 = a;
  b_32bit.uint32 = b;

  if ((a_32bit.exp == 255 && a_32bit.frac != 0) ||
      (b_32bit.exp == 255 && b_32bit.frac != 0)) {  //いずれかがNaNの場合
    result.sign = 0;
    result.exp  = 255;
    result.frac = FRAC_MAX;  // NaN
  } else if ((a_32bit.exp == 255 && b_32bit.exp == 0) ||
	     (a_32bit.exp == 0 && b_32bit.exp == 255)) {
    result.sign = 0;
    result.exp  = 255;
    result.frac = FRAC_MAX;  // NaN
  } else if ((a_32bit.exp == 255) || (b_32bit.exp == 255)) {
    result.sign = a_32bit.sign ^ b_32bit.sign;
    result.exp  = 255;
    result.frac = 0; // inf or -inf
  } else if ((a_32bit.exp == 0) || (b_32bit.exp == 0)) {
    result.sign = a_32bit.sign ^ b_32bit.sign;
    result.exp  = 0;
    result.frac = 0; // どちらか一方が０ならば全て０に。(非正規化数も全て０に。)
  } else {
    
    result.sign = a_32bit.sign ^ b_32bit.sign;
    exp  = a_32bit.exp + b_32bit.exp - 127; // + 129 ??

    a_mant = (1 << 23) | a_32bit.frac;
    b_mant = (1 << 23) | b_32bit.frac;
    a_hmant = a_mant >> 10; //上位14桁を取り出す
    b_hmant = b_mant >> 10;
    a_lmant = a_mant & ((1 << 10) - 1); //下位10桁を取り出す
    b_lmant = b_mant & ((1 << 10) - 1);  
  
    /*
    printf("a_mant  : "); printf("%10llu ", a_mant);  llitobit(a_mant, 25); 
    printf("b_mant  : "); printf("%10llu ", b_mant);  llitobit(b_mant, 25);
    printf("a_hmant : "); printf("%10llu ", a_hmant); llitobit(a_hmant, 14);
    printf("a_lmant : "); printf("%10llu ", a_lmant); llitobit(a_lmant, 10);
    printf("b_hmant : "); printf("%10llu ", b_hmant); llitobit(b_hmant, 14);
    printf("b_lmant : "); printf("%10llu ", b_lmant); llitobit(b_lmant, 10);
    */

    product = (a_hmant * b_hmant) + ((a_hmant * b_lmant) >> 10)
      + ((a_lmant * b_hmant) >> 10); 
    /*
    printf("a_hmant * b_hmant : %10llu\n", a_hmant * b_hmant);
    printf("a_hmant * b_lmant : %10llu\n", a_hmant * b_lmant);
    printf("a_lmant * b_hmant : %10llu\n", a_lmant * b_hmant);
    printf("product : "); printf("%10llu \n", product); 
    llitobit(product, 28);
    */
  
    //仮数部の積のMSBは下から27bit目or28bit目(1,2,..,25,26)
    if ((product & (1 << 27)) == (1 << 27)) { //繰り上がりあり
      //llitobit(FRAC_MAX << 4, 28);
      //printf("--- 1 ---\n"); //debug

      s_bit = or_nbit(product, 2);
      product = product >> 2;
      product = (product << 1) | s_bit;
      result.frac = round_even(product) & FRAC_MAX;
      if (round_even_carry(product) == 1) {
	exp++;
      }
      //result.frac = (product & (FRAC_MAX << 4)) >> 4;
      exp++;
    } else { //繰り上がり無し
      //llitobit(FRAC_MAX << 3, 28);
      //printf("--- 0 ---\n"); //debug

      result.frac = round_even(product) & FRAC_MAX;
      if (round_even_carry(product) == 1) {
	exp++;
      }
      //result.frac = (product & (FRAC_MAX << 3)) >> 3;
    }
    if (exp > 254) {
      result.exp  = 255;
      result.frac = 0;   // inf or -inf
    } else if (exp <= 0) {
      result.exp  = 0;
      result.frac = 0;  //非正規仮数はすべて0にする
    } else {
      result.exp = exp;
    }
  }
  return (result.uint32);
}
