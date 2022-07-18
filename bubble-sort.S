# A bubble sort implementation in loongarch assembly

.data

array:  .word 5, 3, 4, 6, 1
buffer: .space 20

.text

display:
    la $t7, array                   # address of array
    la $t8, buffer                  # address of buffer
    li.w $t0, 0                     # i
    li.w $t6, 5                    
    startLoop:
        beq $t0, $t6, endLoop

        slli.d $t1, $t0, 2
        add.d $t2, $t7, $t1
        ld.d $t3, $t2, 0            # get array[i]
        addi.d $t3, $t3, 0x30       # convert to ascii, only work for < 10 numbers

        add.d $t4, $t8, $t0
        st.b $t3, $t4, 0            # store buffer[i]
        
        addi.d $t0, $t0, 1
        b startLoop
    endLoop:

    li.w  $t0, 13
    st.b $t0, $t8, 5           # '\r'
    li.w  $t0, 10
    st.b $t0, $t8, 6           # '\n'
    st.b $zero, $t8, 7         # zero end the string buffer

    li.w $a7, 64
    li.w $a0, 1
    la $a1, buffer
    li.w $a2, 8
    syscall 0x0                  # write out the string buffer

    jirl $r0, $ra, 0

sort:

/*
    for (int i = 0 ; i < 5 - 1; ++i)
    {
        for (int j = 0 ; j < 5 - 1 - j; ++i)
        {
            if( array[j] > array[j+1] )
            {
                temp = array[j];
                array[j] = array[j+1];
                array[j+1] = temp;
                // swap
            }

        }
    }
*/

    la $s0, array
    li.w $t0, 0 # i
    li.w $t8, 4 # size - 1

sortLoop1:
    beq $t0, $t8, sortEndloop1
        li.w $t1, 0 # j
        sub.w $t2, $t8, $t1

            sortLoop2:
                beq $t1, $t2, sortEndloop2
                    slli.d $t3, $t1, 2
                    add.d $t4, $s0, $t3

                    ld.w $t5, $t4, 0
                    ld.w $t6, $t4, 4

                    blt $t6, $t5, swap
                    b endSwap
                    swap:
                        move $t7, $t5
                        move $t5, $t6
                        move $t6, $t7

                        st.w $t5, $t4, 0
                        st.w $t6, $t4, 4
                    endSwap:
                addi.d $t1, $t1, 1
                b sortLoop2
            sortEndloop2:

    addi.d $t0, $t0, 1
    b sortLoop1
sortEndloop1:
    jirl $r0, $ra, 0


.global main
main:
    bl display
    bl sort
    bl display

    li.w $a7, 93     # exit
    li.w $a0, 0
    syscall 0x0
