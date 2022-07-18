# Loongarch架构汇编快速入门

龙芯常用的汇编器是GNU as汇编器，as的具体使用可以参见[官方文档](https://sourceware.org/binutils/docs/as/)。这里介绍最基础的知识和一些架构相关内容。

## 数据类型和常量

### 数据类型

* 所有LoongArch指令都是32位长的。
* 字节(byte) = 8位(bit)
* 半字(half) = 2个字节
* 字(word) = 4个字节
* 双字(dword) = 8个字节
* 注意，汇编里用.long定义的数据是4个字节

### 常量

* 数字直接输入，如：1234
* 单个字符用单引号，例如：'a'
* 字符串用双引号，例如："hello world"

## 寄存器和ABI

* LoongArch下一共有32个通用定点寄存器
* 在汇编中，寄存器标志由$符开头，寄存器表示可以有两种方式
    - 直接使用该寄存器对应的编号，例如：从$0到$31
    - 使用对应的寄存器名称，例如：$a0, $t1，详细含义参见龙架构ABI文档。
* 栈的走向是从高地址到低地址

### 龙架构ABI

二进制程序接口(Application Binary Interface)是为了实现二进制模块之间的交互引入的人为约定，包括寄存器使用、如何在子程序之间传递参数，数据类型，对齐，系统调用等内容。龙架构的ABI总体遵循SysV ABI框架，架构相关的约定参见[官方文档](https://loongson.github.io/LoongArch-Documentation/LoongArch-ELF-ABI-EN.html)

## 程序结构

包括数据声明和程序代码，通常保存为后缀.s或者.S的文本文件。一般先是数据声明，后是代码段。

### 数据声明

* 以汇编伪指令 .data开始
* 声明程序用到的变量名字，并在内存中分配空间

### 代码

* 代码段以 .text为开始标志
* 包括程序指令
* 程序入口为main：标签所在位置
* 程序结束时应该用exit系统调用（参见后文系统调用一节）

## 注释

* 一行中#字符之后的内容

## 一个LoongArch汇编程序模板

```bash

\# 描述此程序名字和功能的注释
\# Template.s
\# 汇编程序模板

.data # 本行之后是数据声明
...


.text # 指令在本行之后开始

main:  # 程序入口
...


## 数据声明格式

声明的格式：

    name:       storage_type	value(s)	
    变量名:     数据类型         变量值     

* 创建给定类型、名字和值的变量，值是是该变量的初始值
* 注意：名字后面要跟英文冒号

例子：

    var1:		.word	3	# 声明一个 word 类型的变量 var1, 同时给其赋值为 3
    array1:		.byte	'a','b'	# 声明一个存储2个字符的数组 array1，并赋值 'a', 'b'
    array2:		.space	40	# 为变量 array2 分配 40字节（bytes)未使用的连续空间，当然，对于这个变量
    　　　　　　　　　　　　# 到底要存放什么类型的值， 最好事先声明注释下！
     
## 汇编伪指令

汇编伪指令(directive)是由.打头的一些特殊标记符，它指示汇编器做一些特定的动作，如前述介绍的.word/.data等。龙架构的汇编伪指令由GNU as汇编器支持的所有架构无关伪指令和它特有的伪指令组成。

架构无关伪指令的详细情况，可以参见[binutils的伪操作](https://sourceware.org/binutils/docs/as/Pseudo-Ops.html)。常用的伪指令包括：

* .data/.text/.section等，用于定义elf的section（节）开始，把后续的代码或者数据放置到那个elf节。
* .global，把函数名或者变量名声明为全局变量，例如汇编程序的main要定义为global，缺省的链接才会成功。
* .align n，定义2^n对齐
* .if/.ifxx/.elseif/.else/.endif，条件编译控制
* .macro，定义汇编宏代码块，可以带参数
* .ascii/.asciz，定义字符串，后者以0结尾
* .float/.double，定义单精度、双精度浮点
* .include，包含另一个汇编源文件

后者目前仅有几个，可以从binutils源代码gas/config/tc-loongarch.c中的loongarch_pseudo_table看到，包括：

* .align
* .dword，定义8字节的双字
* .word, 字
* .half, 半字
* .dtprelword, dwarf调试信息用的一种重定位伪指令
* .dtpreldword, dwarf调试信息用的一种重定位伪指令

## 常用指令

* Load/Store访存指令，参见[这个表](https://foxsen.github.io/archbase/sec-ISA.html#tab:mem-inst)。
* 算术逻辑指令。参见[这个表](https://foxsen.github.io/archbase/sec-ISA.html#tab:alu-inst)
* 控制流指令。参见[这个表](https://foxsen.github.io/archbase/sec-ISA.html#tab:control-inst)

## 地址空间安排

普通汇编程序可以使用gcc工具链提供的缺省链接脚本，由编译器选择缺省的程序代码段、数据段装载地址。如果有特殊需要，可以使用GNU ld链接程序的链接脚本支持，灵活指定代码或者数据被装载的地址。

## 代码案例


