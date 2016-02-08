/* コンパイル時　gcc finvtable.c finv.c -lm */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include "def.h"
#include "finvtable.h"
//#include "table.h"

#define MAX 2048
#define MASK11 8384512  //((1 << 11) - 1) << 12
#define MASK10 8380416

//uint32_t fadd(uint32_t a, uint32_t b);

//uint32_t fmul(uint32_t a, uint32_t b);


static double make_a(double t, double c) {
  double a;
  a = 1 / (t * (t+c));
  return a;
}

static double make_b(double t, double c) {  //テーブル化する部分
  double b, temp;
  temp = sqrt(1/t) + sqrt(1/(t+c));
  b = (temp * temp) / 2;
  return b;
}

uint32_t finv(uint32_t org) {   
  double a_db,b_db,c,t;
  unsigned int index, tmp, t1;
  union data_32bit a,b,fraction,result,original;
  int d;
  
  original.uint32 = org;

  if (original.exp == 255 && original.frac != 0) {
    result.sign = 0;
    result.exp  = 255;
    result.frac = FRAC_MAX; // NaN -> NaN
  } else if (original.sign == 0 && original.exp == 0) {
    result.uint32 = INF;    //非正規仮数(正)は0として処理。要修正
  } else if (original.sign == 1 && original.exp == 0) {
    result.uint32 = NINF;   //非正規仮数(負)は-0として処理
  } else if (original.uint32 == INF) {
    result.uint32 = ZERO;
  } else if (original.uint32 == NINF) {
    result.uint32 = NZERO;
  } else {


    if (original.frac == 0) {
      result.uint32 = org;
      if (original.exp >= 127) {
	d = original.exp - 127;
	result.exp = 127 - d;
      } else {
	d = 127 - original.exp;
	result.exp = 127 + d;
      }
    } else {
      fraction.uint32 = org;
      fraction.exp = 127;
      fraction.sign = 0;

/*  直線補間による逆数演算  */

  /*  精度の高い方  */
/*
      c = 1.0 / MAX;
      index = (fraction.frac & MASK11) >> 12;   //テーブルサイズが11bit
      t = 1 + (c * index);
      a_db = make_a(t,c) * (-1);
      b_db = make_b(t,c);
      a.fl32 = (float)a_db;
      b.fl32 = (float)b_db;
      fraction.uint32 = fadd(fmul(a.uint32, fraction.uint32), b.uint32);
*/    

  /*  vhdlと同じ実装  */
      index = (/*fraction.frac*/org & MASK10) >> 13;
      tmp = makevhd_ab(index, 0) * (original.frac & 8191u);
      t1 = tmp >> 12;
      fraction.frac = makevhd_ab(index, 1) - t1;
  
  
      result.sign = original.sign;
      if (original.exp >= 127) {
	d = original.exp - 127;
	if (d < 126) {  // d = 128:already excluded , 127,126:非正規化数->ZEROとして扱う  
	  result.exp = 127 - d - 1;
	  result.frac = fraction.frac;
	} else {
	  result.exp = 0;
	  result.frac = 0;
	}
      } else {
	d = 127 - original.exp;
	result.exp = 127 + d - 1;
	result.frac = fraction.frac;
      }
    }
  }
  return (result.uint32);
}

