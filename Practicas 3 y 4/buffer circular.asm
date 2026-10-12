.data
	msg: .asciiz "Programa esperando teclas\n"
	buffer: .space 20
	indice: .word 0				#indice para controlar el buffer.
.text
	la $s0, buffer

	li $v0, 4
	la $a0, msg				#se imprime el primer mensaje.
	syscall

	li $t0, 0xffff0000			#habilita al teclado hacer interrupciones.
	li $t1, 2
	sw $t1, 0($t0)

	mfc0 $t0, $12				#habilita las interrupciones globales.
	ori $t0, $t0, 1
	mtc0 $t0, $12
	
	li $v0, 30				#en $s2 se guarda el tiempo actual.
	syscall
	move $s2, $a0
	
	ciclo:
	li $v0, 30	
	syscall
	
	subu $t0, $a0, $s2			#se compara constantemente el tiempo actual con el de $s2.
	
	li $t1, 20000
	bge $t0, $t1, imprimir_buffer		#si la diferencia entre los dos es mayor a 20 segundos se imprime el buffer.
	j ciclo
	
	imprimir_buffer:
	li $t0, 0
	li $t1, 20
	ciclo_imprimir:
	beq $t0, $t1, reiniciar_todo		#ciclo para imprimir y vaciar el buffer.
	add $t2, $s0, $t0
	lb $a0, 0($t2)
	sb $zero, 0($t2)
	
	li $v0, 11
	syscall
	
	addi $t0, $t0, 1
	j ciclo_imprimir
	
	reiniciar_todo:				#despues de imprimirse el buffer se reinicia el indice a 0.
	la $t0, indice
	sw $zero, 0($t0)
	li $v0, 30
	syscall					#tambien se reinicia el tiempo que contiene $s2.
	move $s2, $a0
	j ciclo					#vuelve al ciclo hasta que vuelvan a transcurrir 20 seg de nuevo.

	.ktext 0x80000180			#direccion a donde se van las interrupciones.

	handler:
	
	.set noat				#guardar el contexto.
	move $k0, $at
	.set at
	
	addi $sp, $sp, -32
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $v0, 28($sp)
	
	teclado_interrupcion:
	
	li $t0, 0xffff0004			#se recibe desde el teclado un caracter.
	lb $t1, 0($t0)
	
	li $t2, 65
	blt $t1, $t2, fin			#aqui pregunta si es mayuscula, si no lo ignora.
	li $t2, 90
	bgt $t1, $t2, fin
	
	la $t5, indice
	la $t6, buffer
	lw $t3, 0($t5)
	add $t4, $t3, $t6
	sb $t1, 0($t4)				#guarda en el buffer el caracter si es mayuscula.
	addi $t3, $t3, 1			#se incrementa el indice.
	sw $t3, 0($t5)
	
	li $t4, 20				#revisa si el indice es igual al tamaño del buffer.
	bne $t3, $t4, fin
	li $t3, 0				#si es igual se reinicia a 0, ya que es un buffer circular.
	sw $t3, 0($t5)

	fin:
	lw $t0, 0($sp)				#se restaura el contexto.
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $v0, 28($sp)
	addi $sp, $sp, 32
	
	.set noat
	move $at, $k0
	.set at
	eret					#se devuelve a donde ocurrio la interrupcion.
