.data

string: .asciz "Hello World!\r\n"

.text
.global main
main:

    li.w $a7, 64              # write syscall number
    li.w $a0, 1               # stdout file descriptor == 1
    la $a1, string            # string address
    li.w $a2, 15              # string len
    syscall 0x0               # syscall

    li.w $a7, 93              # exit syscall number
    li.w $a0, 0
    syscall 0x0               # syscall

