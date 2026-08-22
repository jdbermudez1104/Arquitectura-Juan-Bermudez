# ACTIVIDAD 2: ALGORITMO DE ORDENAMIENTO MERGESORT EN MIPS32
.data
    array:      .word 15, 9, 81, 17, 4, 3, 22, 11, 45, 2    # Arreglo a ordenar
    size:       .word 10                                    # Tamaño
    temp:       .space 40                                   # Arreglo auxiliar (10 * 4 bytes)
    msg_orig:   .asciiz "Arreglo original:\n"
    msg_ord:    .asciiz "\nArreglo ordenado con Mergesort:\n"
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

    # Ejecutar Mergesort: mergesort(array, 0, size - 1)
    la $a0, array
    li $a1, 0
    lw $a2, size
    addi $a2, $a2, -1
    jal mergesort

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

# Subrutina: mergesort(arr[], left, right)
mergesort:
    # Guardar en pila
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s3, 12($sp)             # mid
    sw $s2, 8($sp)              # right
    sw $s1, 4($sp)              # left
    sw $s0, 0($sp)              # base array

    move $s0, $a0
    move $s1, $a1
    move $s2, $a2

    # Condición de parada: if (left < right)
    slt $t0, $s1, $s2
    beq $t0, $zero, end_mergesort

    # mid = left + (right - left) / 2
    sub $t0, $s2, $s1
    sra $t0, $t0, 1
    add $s3, $s1, $t0

    # Llamada recursiva 1: mergesort(arr, left, mid)
    move $a0, $s0
    move $a1, $s1
    move $a2, $s3
    jal mergesort

    # Llamada recursiva 2: mergesort(arr, mid + 1, right)
    move $a0, $s0
    addi $a1, $s3, 1
    move $a2, $s2
    jal mergesort

    # Mezclar subarreglos: merge(arr, left, mid, right)
    move $a0, $s0
    move $a1, $s1
    move $a2, $s3
    move $a3, $s2
    jal merge

end_mergesort:
    # Restaurar pila
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# Subrutina: merge(arr[], left, mid, right)
merge:
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s5, 20($sp)             # k
    sw $s4, 16($sp)             # j
    sw $s3, 12($sp)             # i
    sw $s2, 8($sp)              # right
    sw $s1, 4($sp)              # mid
    sw $s0, 0($sp)              # left

    move $s0, $a1               # left
    move $s1, $a2               # mid
    move $s2, $a3               # right

    move $s3, $s0               # i = left
    addi $s4, $s1, 1            # j = mid + 1
    move $s5, $s0               # k = left

    la $t0, array
    la $t1, temp

merge_loop:
    # Condición: while (i <= mid && j <= right)
    slt $t2, $s1, $s3           # i > mid
    bne $t2, $zero, copy_remaining_left
    slt $t2, $s2, $s4           # j > right
    bne $t2, $zero, copy_remaining_left

    # Obtener arr[i] y arr[j]
    sll $t3, $s3, 2
    add $t3, $t0, $t3
    lw $t4, 0($t3)              # arr[i]

    sll $t5, $s4, 2
    add $t5, $t0, $t5
    lw $t6, 0($t5)              # arr[j]

    # if (arr[i] <= arr[j])
    slt $t7, $t6, $t4
    bne $t7, $zero, take_right

    # temp[k] = arr[i]; i++
    sll $t8, $s5, 2
    add $t8, $t1, $t8
    sw $t4, 0($t8)
    addi $s3, $s3, 1
    j next_merge_step

take_right:
    # temp[k] = arr[j]; j++
    sll $t8, $s5, 2
    add $t8, $t1, $t8
    sw $t6, 0($t8)
    addi $s4, $s4, 1

next_merge_step:
    addi $s5, $s5, 1
    j merge_loop

copy_remaining_left:
    # while (i <= mid) temp[k++] = arr[i++]
    slt $t2, $s1, $s3
    bne $t2, $zero, copy_remaining_right

    sll $t3, $s3, 2
    add $t3, $t0, $t3
    lw $t4, 0($t3)

    sll $t8, $s5, 2
    add $t8, $t1, $t8
    sw $t4, 0($t8)

    addi $s3, $s3, 1
    addi $s5, $s5, 1
    j copy_remaining_left

copy_remaining_right:
    # while (j <= right) temp[k++] = arr[j++]
    slt $t2, $s2, $s4
    bne $t2, $zero, copy_back

    sll $t5, $s4, 2
    add $t5, $t0, $t5
    lw $t6, 0($t5)

    sll $t8, $s5, 2
    add $t8, $t1, $t8
    sw $t6, 0($t8)

    addi $s4, $s4, 1
    addi $s5, $s5, 1
    j copy_remaining_right

copy_back:
    # Copiar temp[left...right] de vuelta a arr[left...right]
    move $t2, $s0               # index = left

copy_back_loop:
    slt $t3, $s2, $t2
    bne $t3, $zero, end_merge

    sll $t4, $t2, 2
    add $t5, $t1, $t4           # &temp[index]
    lw $t6, 0($t5)

    add $t7, $t0, $t4           # &arr[index]
    sw $t6, 0($t7)

    addi $t2, $t2, 1
    j copy_back_loop

end_merge:
    # Restaurar pila
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra

# Subrutina Auxiliar: print_array(arr[], size)
print_array:
    move $t0, $a0
    move $t1, $a1
    li $t2, 0

print_loop:
    beq $t2, $t1, print_end

    sll $t3, $t2, 2
    add $t3, $t0, $t3
    lw $a0, 0($t3)
    li $v0, 1
    syscall

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