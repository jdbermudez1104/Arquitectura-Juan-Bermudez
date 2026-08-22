#ALGORITMO DE ORDENAMIENTO QUICKSORT EN MIPS32
.data
    array:      .word 12, 3, 5, 7, 19, 1, 8, 6, 2, 4    # Arreglo a ordenar
    size:       .word 10                                # Tamaño del arreglo
    msg_orig:   .asciiz "Arreglo original:\n"
    msg_ord:    .asciiz "\nArreglo ordenado con Quicksort:\n"
    space:      .asciiz " "
    newline:    .asciiz "\n"

.text
.globl main

main:
    # Imprimir mensaje inicial
    li $v0, 4
    la $a0, msg_orig
    syscall

    # Imprimir arreglo original
    la $a0, array
    lw $a1, size
    jal print_array

    # Ejecutar Quicksort: quicksort(array, 0, size - 1)
    la $a0, array               # $a0 = dirección base
    li $a1, 0                   # $a1 = low = 0
    lw $a2, size
    addi $a2, $a2, -1           # $a2 = high = size - 1
    jal quicksort

    # Imprimir mensaje final
    li $v0, 4
    la $a0, msg_ord
    syscall

    # Imprimir arreglo ordenado
    la $a0, array
    lw $a1, size
    jal print_array

    # Salir del programa
    li $v0, 10
    syscall

# Subrutina: quicksort(arr[], low, high)
quicksort:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s2, 8($sp)
    sw $s1, 4($sp)
    sw $s0, 0($sp)

    move $s0, $a1               # low
    move $s1, $a2               # high

    slt $t0, $s0, $s1
    beq $t0, $zero, end_quicksort

    # partition(arr, low, high)
    la $a0, array
    move $a1, $s0
    move $a2, $s1
    jal partition
    move $s2, $v0               # p = índice pivote

    # quicksort(arr, low, p - 1)
    la $a0, array
    move $a1, $s0
    addi $a2, $s2, -1
    jal quicksort

    # quicksort(arr, p + 1, high)
    la $a0, array
    addi $a1, $s2, 1
    move $a2, $s1
    jal quicksort

end_quicksort:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

# Subrutina: partition(arr[], low, high) -> $v0
partition:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s4, 16($sp)             # pivot
    sw $s3, 12($sp)             # j
    sw $s2, 8($sp)              # i
    sw $s1, 4($sp)              # high
    sw $s0, 0($sp)              # low

    move $s0, $a1               # low
    move $s1, $a2               # high

    # pivot = arr[high]
    la $t0, array
    sll $t1, $s1, 2
    add $t1, $t0, $t1
    lw $s4, 0($t1)              # pivot

    addi $s2, $s0, -1           # i = low - 1
    move $s3, $s0               # j = low

loop_partition:
    slt $t0, $s3, $s1           # j < high ?
    beq $t0, $zero, end_partition_loop

    # arr[j]
    la $t0, array
    sll $t1, $s3, 2
    add $t1, $t0, $t1
    lw $t2, 0($t1)

    # if (arr[j] <= pivot)
    slt $t3, $s4, $t2           # pivot < arr[j] ?
    bne $t3, $zero, next_j

    addi $s2, $s2, 1           # i++
    move $a0, $s2
    move $a1, $s3
    jal swap

next_j:
    addi $s3, $s3, 1
    j loop_partition

end_partition_loop:
    addi $s2, $s2, 1           # i + 1
    move $a0, $s2
    move $a1, $s1
    jal swap

    move $v0, $s2               # Retorna i + 1

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra



# Subrutina Auxiliar: swap(i, j)
swap:
    la $t0, array
    sll $t1, $a0, 2             # offset i
    add $t1, $t0, $t1           # &arr[i]

    sll $t2, $a1, 2             # offset j
    add $t2, $t0, $t2           # &arr[j]

    lw $t3, 0($t1)              # temp1 = arr[i]
    lw $t4, 0($t2)              # temp2 = arr[j]

    sw $t4, 0($t1)              # arr[i] = arr[j]
    sw $t3, 0($t2)              # arr[j] = temp1
    jr $ra
    
print_array:
    move $t0, $a0               # Base del arreglo
    move $t1, $a1               # Tamaño
    li $t2, 0                   # Índice i = 0

print_loop:
    beq $t2, $t1, print_end

    # Cargar e imprimir elemento
    sll $t3, $t2, 2
    add $t3, $t0, $t3
    lw $a0, 0($t3)
    li $v0, 1
    syscall

    # Imprimir espacio
    li $v0, 4
    la $a0, space
    syscall

    addi $t2, $t2, 1
    j print_loop

print_end:
    li $v0, 4
    la $a0, newline
    syscall
    jr $ra