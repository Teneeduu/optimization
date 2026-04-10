
这个测试函数库包含了Jones的全部9个函数，对应如下：
shekel5, shekel7, shekel10 一样
hart3 --- H3
hart6 --- H6
branin --- BR
gold --- GP
hump --- C6，后者最优值为-1.3...., 前者加上了这个常数（但精度不够），最优值约等于0。其他函数没仔细核对最优值是否做了类似修正...
shub --- SHU

注意：这个库与iceo96库交叉的函数并不完全一样。
       griewank函数没有偏离100，后者有；
       shekel函数与iceo96里面的shekels不同, 后者是Shekel's foxholes，更复杂。
       sphere函数没有偏离1，后者有。