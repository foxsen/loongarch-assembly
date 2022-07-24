# LoongArch 行内汇编

行内汇编(inline assembly)是GCC编译器支持的一种C/C++语言扩展语法， 用来支持在C/C++高级语言程序中嵌入汇编语句。在C/C++中嵌入汇编主要有两个用处：

1. 优化代码。有时候用汇编能够写出比编译器更高效的代码。
2. 使用处理器特定的指令。比如gcc不认识/不能生成的特殊指令。

行内汇编使用上有不少坑，注意在充分理解的基础上使用。

## 简单asm代码块

行内汇编最简单的形式如下：

    asm asm-qualifiers ("汇编语句");  

这种最简形式可以用于嵌入汇编指令，“汇编语句”可以是一条指令，也可以是多条指令，多条指令的时候可以写成类似如下的形式：

    asm ("inst1 \n\t"
         "inst2 \n\t"
         "inst3 \n\t"
         ...);
    
其中asm也可以为__asm__或者__asm。asm本身是GCC的一个GNU扩展，在写用-ansi/-std c99等选项编译（选择没有GNU扩展）的代码时，可以用__asm__。

### qualifiers

* volatile. 如果行内汇编语句块有一些副作用，你可能需要用volatile来禁止编译器进行一些优化。比如，如果gcc发现asm代码块的输出寄存器没有被用到，它可能会把整个asm代码块丢弃。另外，如果它认为这个代码产生的值一直不会变化，可能会把它移到循环体外部。volatile可以禁止这些优化。没有指定输出操作数的asm代码块缺省是volatile的。
* inline. 让编译器在inline相关决策时把asm代码块的size当做最小的指令大小，而不是它计算的asm块大小。

## 扩展asm代码块

用简单形式的asm代码块无法指定汇编指令操作数和C程序变量的交互关系，也无法跳转到C代码的其他标签。

扩展asm形式则是：

     asm asm-qualifiers ( assembler template 
           : output operands                  /* 可选 */
           [ : input operands                   /* 可选 */
            [: list of clobbered registers ]       /* 可选 */
           ]);

或者：

     asm asm-qualifiers ( AssemblerTemplate 
                      : OutputOperands
                      : InputOperands
                      : Clobbers
                      : GotoLabels)


每个操作数用一个操作数约束字符串加一个括号内的C表达式来描述。第一个冒号分隔汇编语句和输出操作数，第二个冒号分隔输出操作数描述和输入操作数描述，第三个分隔输入操作数描述和被破坏的寄存器描述。在每类的操作数描述中，如果不止一个，则用逗号分隔。如果指令没有输出操作数但有输入操作数，则第一个冒号后面可以为空，但必须有冒号。后面没有更多内容时可以省略冒号，例如没有clobber list则第3个冒号可以不写。编译器将把汇编语句中的操作数引用适当处理后得到的汇编指令发送给gas去汇编。这种形式中，可以不指定操作数具体放到哪个寄存器中，而是让编译器去分配。当然，直接指定具体寄存器也可以，此时要注意保证不破坏前后的C代码，比如修改的寄存器需要列出来让编译器知道。

例：

    int myadd_1(int a, int b)
    {
        int c;
        /* 用"%"加冒号后出现的次序编号来引用操作数
         * c是第1个，编号0，a是第2个，编号1，...
         */
        __asm__ ("add.d %0, %1, %2\n\t"
                 :"=r"(c)
                 :"r"(a), "r"(b)
                 :);
        return c;
    }

    int myadd_2(int a, int b)
    {
        int c;
        /* 在操作数前用'[汇编操作数名]'来给操作数命名
         * 在汇编指令中用%[汇编操作数名]来引用
         */
        __asm__ ("add.d %[result], %[addend1], %[addend2]\n\t"
                 :[result] "=r"(c)
                 :[addend1] "r"(a), [addend2] "r"(b)
                 :);
        return c;
    }


myadd_1中，c是输出寄存器，"=r"是其操作数描述字符串，给这个参数数添加一些限定说明。"r"表示这个变量要分配到寄存器中，"="表示要写该寄存器。在汇编语句中，用%0, %1这样的方式去引用操作数，%0表示冒号后第一个操作数（输入、输出都统一从0开始编号）。

用编号容易出错，也可以类似myadd_2那样给操作数取个汇编语句中用的名字以便引用。

### qualifiers

* volatile. 如果行内汇编语句块有一些副作用，你可能需要用volatile来禁止编译器进行一些优化。比如，如果gcc发现asm代码块的输出寄存器没有被用到，它可能会把整个asm代码块丢弃。另外，如果它认为这个代码产生的值一直不会变化，可能会把它移到循环体外部。volatile可以禁止这些优化。没有指定输出操作数的asm代码块缺省是volatile的。
* inline. 让编译器在inline相关决策时把asm代码块的size当做最小的指令大小，而不是它计算的asm块大小。
* goto. 告诉编译器这个asm代码块可能会跳转到gotoLabel列出的那些跳转标签。

### 汇编语句模板

汇编语句模板中可以包括一条或者多条指令，可以把每条指令都用双引号包起来，或者在一个双引号中连续写多条指令；指令之间应该有合法的分隔符(\n或者;) 总体上语法和纯汇编文件的写法基本一致（LoongArch嵌入式汇编没有intel语法还是AT&T语法的说法，只有一种格式），只是其中的操作数表示多了一些和C挂钩的表示方式，如上述介绍的%n以及%[name]。GCC把汇编语句模板里边的指令的操作数、跳转标签等替换为汇编指令认识的寄存器号等内容，然后把代码块给汇编器去汇编。编译器并不分析每条指令的语法和依赖关系等。

### 操作数

操作数的基本形式是：

    "constraint" (C表达式)

constraint（约束）用来决定操作数的寻址模式、用哪个寄存器等。

输出操作数的表达式必须是左值。常规的输出操作数是只写的，编译器会假设相应的汇编指令之前该操作数原有的值已经失效。扩展汇编语法也支持既输入又输出的操作数。

如上述myadd_1例子中，%0对于变量c，是输出操作数，用寄存器访问，对于的约束是"=r"。如果要改为a = a + b，则可以写为：


    int myadd_3(int a, int b)
    {
        /* a = a + b;
         * "0"表示引用第一个操作数
         */
        __asm__ ("add.d %0, %1, %2\n\t"
                 :"=r"(a)
                 :"0"(a), "r"(b)
                 :);
        return a;
    }

此时a既是输入操作数，又是输出操作数，输入操作数约束"0"表示它和第1个操作数相同。    

myadd_3中，具体%0,%2对应哪个寄存器由编译器决定。LoongArch约束描述没法直接指定变量到某个特定寄存器(在x86中，用"a","b","c"等可以指定ax/bx/cx等寄存器)。LoongArch中如果需要把某个C变量绑定到特定寄存器，可以用gcc的local/global register variable语法，例如：

    register int a asm("$a0");

### LoongArch支持的约束

目前(gcc 12.0.0)LoongArch编译器支持如下约束：

* "a" "A constant call global and noplt address."
* "b" <-----unused
* "c" "A constant call local address."
* "d" <-----unused
* "e" JIRL_REGS
* "f" FP_REGS
* "g" <-----unused
* "h" "A constant call plt address."
* "i" "Matches a general integer constant." (Global non-architectural)
* "j" SIBCALL_REGS
* "k" "A memory operand whose address is formed by a base register and (optionally scaled) index register."
* "l" "A signed 16-bit constant."
* "m" "A memory operand whose address is formed by a base register and offset that is suitable for use in instructions with the same addressing mode as st.w and ld.w."
* "n" "Matches a non-symbolic integer constant." (Global non-architectural)
* "o" "Matches an offsettable memory reference." (Global non-architectural)
* "p" "Matches a general address." (Global non-architectural)
* "q" CSR_REGS
* "r" GENERAL_REGS (Global non-architectural)
* "s" "Matches a symbolic integer constant." (Global non-architectural)
* "t" "A constant call weak address"
* "u" "A signed 52bit constant and low 32-bit is zero (for logic instructions)"
* "v" "A signed 64-bit constant and low 44-bit is zero (for logic instructions)."
* "w" "Matches any valid memory."
* "x" <-----unused
* "y" <-----unused
* "z" FCC_REGS
* "A" <-----unused
* "B" <-----unused
* "C" <-----unused
* "D" <-----unused
* "E" "Matches a floating-point constant." (Global non-architectural)
* "F" "Matches a floating-point constant." (Global non-architectural)
* "G" "Floating-point zero."
* "H" <-----unused
* "I" "A signed 12-bit constant (for arithmetic instructions)."
* "J" "Integer zero."
* "K" "An unsigned 12-bit constant (for logic instructions)."
* "L" <-----unused
* "M" <-----unused
* "N" <-----unused
* "O" <-----unused
* "P" <-----unused
* "Q" <-----unused
* "R" <-----unused
* "S" <-----unused
* "T" <-----unused
* "U" <-----unused
* "V" "Matches a non-offsettable memory reference." (Global non-architectural)
* "W" <-----unused
* "X" "Matches anything." (Global non-architectural)
* "Y" 
    - "Yd" : "A constant move_operand that can be safely loaded using la."
    - "Yx" : "internal"
* "Z" 
    - "ZC" : "A memory operand whose address is formed by a base register and offset that is suitable for use in instructions with the same addressing mode as ll.w and sc.w."
    - "ZB" : "An address that is held in a general-purpose register. The offset is zero"
* "<" "Matches a pre-dec or post-dec operand." (Global non-architectural)
* ">" "Matches a pre-inc or post-inc operand." (Global non-architectural)

其中后面标注(Global non-architecture)的是架构无关的公共约束，其他是LoongArch架构相关的约束。

应该根据具体汇编指令的操作数支持情况来选用约束，相应的C表达式也需要满足约束条件。

例如，下面的例子编译时会报错：

    void test(void)
    {
        unsigned long a,b,offset;

        asm ("lw %0, %1, %2"
                :"=r"(a)
                :"r"(b),"I"(offset)
                :);
    }

错误信息是：

    inline-assembly.c: 在函数‘test’中:
    inline-assembly.c:55:5: 警告：‘asm’ operand 2 probably does not match constraints
       55 |     asm ("lw %0, %1, %2"
          |     ^~~
    inline-assembly.c:55:5: 错误：‘asm’中不可能的约束

可以改成和"I"约束匹配的12位常数：

    void test(void)
    {
        unsigned long a,b;

        asm ("ld.d %0, %1, %2"
              :"=r"(a)
              :"r"(b),"I"(0x12)
              :);
    }

或者让编译器去把一个地址变成寄存器加偏移的形式：

void test2(void)
{
    unsigned long a,b;

    asm ("ld.d %0, %1"
          :"=r"(a)
          :"m"(b)
          :);
}

### 被破坏(clobbered)内容列表


如果汇编指令部分修改了寄存器或者内存内容，而且这些寄存器或者内存没有在输入输出操作数的约束条件中指明，则行内汇编语句需要在第三个冒号后面列出将被破坏的寄存器及内存等内容。对于在输入输出操作数中指明的寄存器和内存修改，则不需要额外说明(事实上如果输入输出操作数中的寄存器和clobbered list寄存器存在相同会报错)，编译器可以自行推断。

需要列明的一种情况是指令直接使用了物理寄存器号作为操作数。

例如，在下面的例子中，行内汇编修改了$t0, $t1两个寄存器，但没有把他们加入clobbered list，如果用-O2去编译这个函数，输出将是a = 2, b = 2, c = 1

    void test3(int a)
    {
        register int b asm("$t0") = a;
        register int c asm("$t1") = 0;

        __asm__ ("addi.w $t0, $zero, 0x2\n\t"
                 "addi.w $t1, $zero, 1\n\t"
                 :::);

        a = a + 1;
        b = b + 1;
        c = c + 1;

        printf("a = %d, b = %d, c = %d\n", a, b, c);
    }

对应的反汇编代码如下：

    0000000120000884 <test3>:
       120000884:   0280080c    addi.w          $t0, $zero, 2(0x2) //嵌入汇编1
       120000888:   0280040d    addi.w          $t1, $zero, 1(0x1) //嵌入汇编2
       12000088c:   02800486    addi.w          $a2, $a0, 1(0x1)   //编译器从输入输出约束推断行内汇编和其他语句无关，认为a = 初始值a0 + 1 = 2
       120000890:   02800407    addi.w          $a3, $zero, 1(0x1) // c = 初始值0 + 1 = 1，实际上c对应的寄存器已经被行内汇编修改
       120000894:   001500c5    move            $a1, $a2           // b = 初始值a0 + 1 = 2，实际上b对应的寄存器已经被行内汇编修改
       120000898:   1c000ae4    pcaddu12i       $a0, 87(0x57)
       12000089c:   02ee8084    addi.d          $a0, $a0, -1120(0xba0)
       1200008a0:   50609400    b               24724(0x6094)   # 120006934 <_IO_printf>

如果加上clobbered list，告诉编译器t0/t1已经被破坏:

    void test4(int a)
    {
        register int b asm("$t0") = a;
        register int c asm("$t1") = 0;

        __asm__ ("addi.w $t0, $zero, 0x2\n\t"
                 "addi.w $t1, $zero, 1\n\t"
                 :::"$t0","$t1");

        a = a + 1;
        b = b + 1;
        c = c + 1;

        printf("a = %d, b = %d, c = %d\n", a, b, c);
    }

此时-O2优化后的输出变为a = 2, b = 3, c = 2，编译器不会直接改变__asm__语句和其他语句的次序，从而得出预期的数值。对应的反汇编代码如下：

    00000001200008a4 <test4>:
       1200008a4:   00150085    move            $a1, $a0
       1200008a8:   0280080c    addi.w          $t0, $zero, 2(0x2)
       1200008ac:   0280040d    addi.w          $t1, $zero, 1(0x1)
       1200008b0:   1c000ae4    pcaddu12i       $a0, 87(0x57)
       1200008b4:   02ee2084    addi.d          $a0, $a0, -1144(0xb88)
       1200008b8:   028005a7    addi.w          $a3, $t1, 1(0x1)
       1200008bc:   02800586    addi.w          $a2, $t0, 1(0x1)
       1200008c0:   028004a5    addi.w          $a1, $a1, 1(0x1)
       1200008c4:   50607000    b               24688(0x6070)   # 120006934 <_IO_printf>


如果编译不加-O2，则test3/test4的输出是一样的。此时编译器没有试图去优化程序，因此是否知道asm修改t0/t1没影响。 gcc依赖于asm语句的输入输出约束去判断这个行内汇编代码块是否读取和修改某些寄存器和内存值，并以此为根据去决定它和前后相关代码的优化，而不是去分析每条指令。

另一种常见情况是汇编指令部分可能以一种无法预期的方式修改内存，此时，为了安全起见，应该让编译器不依赖缓存在寄存器的内存数据（asm语句前写回内存，语句后重新从内存取），clobbered list可以加上"memory"。例如，某个传入的地址参数可能指向任意地址，汇编指令修改了它指向的内容；或者syscall这类指令理论上可以在例外处理里边做任何事情的指令。

### 约束修饰符

在上述约束字母的前面可以添加约束修饰符(constraint modifier)，常用的修饰符包括：

* '='，表示这个操作数会被这条指令写入
* '+'，表示这个操作数既被指令读也被写入
* '&'，表示这个操作数是'earlyclobber'，即这个操作数会在输入操作数被全部使用完之前就被写入。因此，这种操作数不能保存在一个被指令读的寄存器，也不能用来构成内存地址。仅当读出会在写入之前发生的时候，这种操作数才能和一个输入操作数绑定。 earlyclobber操作数本身是一种特殊的会被写入的操作数。 缺省情况下，编译器会认为所有输入寄存器都被使用之后才会开始改变输出寄存器。如果不是这样，就需要告诉它。

例如，在以下的例子中，

    void test5(void) {
        int in = 1;
        int out;
        __asm__ (
                "add.w %[out], %[in], $zero;" /* out = in */
                "addi.w %[out], %[out], 1;" /* out++ */
                "add.w %[out], %[in], $zero;" /* out = in */
                "addi.w %[out], %[out], 1;" /* out++ */
                : [out] "=&r" (out)
                : [in] "r" (in)
                :
                );
        if (out != 2)
            printf("error\n");
    }

如果没有&修饰符，编译器可能给in和out分配相同的寄存器，导致代码错误。

## 一些linux内核实例

### arch_atomic64_sub_if_positive

    static inline long arch_atomic64_sub_if_positive(long i, atomic64_t *v)
    {
        long result;
        long temp;

        if (__builtin_constant_p(i)) {
            __asm__ __volatile__(
            "1: ll.d    %1, %2  # atomic64_sub_if_positive  \n"
            "   addi.d  %0, %1, %3              \n"
            "   or  %1, %0, $zero               \n"
            "   blt %0, $zero, 2f               \n"
            "   sc.d    %1, %2                  \n"
            "   beq %1, $zero, 1b               \n"
            "2:                         \n"
            __WEAK_LLSC_MB
            : "=&r" (result), "=&r" (temp),
              "+" GCC_OFF_SMALL_ASM() (v->counter)
            : "I" (-i));
        } else {
            __asm__ __volatile__(
            "1: ll.d    %1, %2  # atomic64_sub_if_positive  \n"
            "   sub.d   %0, %1, %3              \n"
            "   or  %1, %0, $zero               \n"
            "   blt %0, $zero, 2f               \n"
            "   sc.d    %1, %2                  \n"
            "   beq %1, $zero, 1b               \n"
            "2:                         \n"
            __WEAK_LLSC_MB
            : "=&r" (result), "=&r" (temp),
              "+" GCC_OFF_SMALL_ASM() (v->counter)
            : "r" (i));
        }

        return result;
    }

其中__WEAK_LLSC_MB在smp时定义为"dbar 0"，单核时为空行；GCC_OFF_SMALL_ASM()即"ZC"。

可以看到，result/temp两个输出操作数都用了"=&r"，表示是一个earlyclobber的输出寄存器，它们不会和输入操作数分配同一个寄存器

### sync

    \#define __sync()	__asm__ __volatile__("dbar 0" : : : "memory")

### tlb操作

    /*
     * TLB Invalidate Flush
     */
    static inline void tlbclr(void)
    {
        __asm__ __volatile__("tlbclr");
    }

    static inline void tlbflush(void)
    {
        __asm__ __volatile__("tlbflush");
    }

### xchg_asm

    \#define __xchg_asm(amswap_db, m, val)       \
    ({                      \
            __typeof(val) __ret;        \
                            \
            __asm__ __volatile__ (      \
            " "amswap_db" %1, %z2, %0 \n"   \
            : "+ZB" (*m), "=&r" (__ret) \
            : "Jr" (val)            \
            : "memory");            \
                            \
            __ret;              \
    })

"Jr"表示val可以是整数0或者某个能放到寄存器的变量。

## 参考文献

* [GCC inline assembly howto](https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html)
* [GCC manual for inline assembly](https://gcc.gnu.org/onlinedocs/gcc/Using-Assembly-Language-with-C.html#Using-Assembly-Language-with-C)

