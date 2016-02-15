FPU係がやったこと

fadd,fmul,finv,fsqrt,itof(conv),ftoi(trnc)をc,vhdl実装した。
fadd,fmul以外はパイプライン化した。
finv,fsqrt -> 3clk
ftoi       -> 1clk
itof       -> 3clk (2clkのものも作ったが動作未検証のためとりあえず3clkのを)

fadd,fmulはiseのbehaviorに於いて3clkで動作するものを作ったが、post-routeや実機でコーナーケース検出用フラグがうまく働かないため使用できなかった。
finv,fsqrtのテーブルは本体と別に用意し、10bitをkeyに切片を23bit,傾きを13bitで返すようにした。
特にfmulではなるべく丸め処理を端折って遅延を抑えた。
多用する関数はdef.c、fpu_common.vhdにまとめてある。
