#include <stdio.h>

int ret_1(void) 
{
    int ret;

    __asm__ ("addi.d %0, $zero, 123"
              :"=r"(ret)
              ::);
    return ret;
}

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

void test1(void)
{
    unsigned long a,b;

    asm ("ld.d %0, %1, %2"
          :"=r"(a)
          :"r"(b),"I"(0x12)
          );
}

void test2(void)
{
    unsigned long a,b;

    asm ("ld.d %0, %1"
          :"=r"(a)
          :"m"(b)
          :);
}

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
        printf("test5 error\n");
    else
        printf("test5 ok\n");
}

void test6(void) {
    int in = 1;
    int out;
    __asm__ (
            "add.w %[out], %[in], $zero;" /* out = in */
            "addi.w %[out], %[out], 1;" /* out++ */
            "add.w %[out], %[in], $zero;" /* out = in */
            "addi.w %[out], %[out], 1;" /* out++ */
            : [out] "=r" (out)
            : [in] "r" (in)
            :
            );
    if (out != 2)
        printf("test6 expected error\n");
    else
        printf("test6 failed\n");
}

int main(int argc, char **argv)
{
    int a = 3, b = 5;

    /* 最简单的形式 */
    asm ("nop");
    /* asm 和 __asm__、__asm基本等价，但-ansi/-std c99等选项下不认asm */
    __asm__ ("nop");
    __asm ("nop");

    printf("ret_1 ret %d\n", ret_1());
    printf("myadd_1 = %d\n", myadd_1(a, b));
    printf("myadd_2 = %d\n", myadd_2(a, b));
    printf("myadd_3 = %d\n", myadd_3(a, b));

    test3(1);
    test4(1);
    test5();
    test6();

    return 0;
}


