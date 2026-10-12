.data
	msg1: .asciiz "Semáforo en verde, esperando pulsador\n"
	msg2: .asciiz "Pulsador activado: en 20 segundos, el semáforo cambiará a amarillo\n"
	msg3: .asciiz "Semáforo en amarillo, en 10 segundos, semáforo en rojo\n"
	msg4: .asciiz "Semáforo en rojo, en 30 segundos, semáforo en verde\n"
	pulsador: .word 0			#bandera para saber si fue pulsada la "s".
.text
	
	li $t0, 0xffff0000			#habilita al teclado hacer interrupciones.
	li $t1, 2
	sw $t1, 0($t0)
	
	mfc0 $t0, $12				#habilita las interrupciones globales.
	ori $t0, $t0, 1
	mtc0 $t0, $12
	
	regresar:				#el pulsador vuelve a 0.
	la $t0, pulsador
	sw $zero, 0($t0)
	
	li $v0, 4				#se imprime el primer mensaje.
	la $a0, msg1
	syscall
	
	ciclo:					#ciclo infinito hasta que el pulsador cambie a 1.
	la $t0, pulsador
	lw $t1, 0($t0)
	beq $t1, $zero, ciclo
	
	li $v0, 4
	la $a0, msg2				#si cambia el pulsador, se imprime el segundo mensaje.
	syscall
	
	li $v0, 32				#se "duerme" el programa durante 20 segundos.
	li $a0, 20000
	syscall
	
	li $v0, 4
	la $a0, msg3				#se imprime el tercer mensaje, ya acabados los 20 segundos.
	syscall
	
	li $v0, 32				#se "duerme" el programa durante 10 segundos.
	li $a0, 10000
	syscall
	
	li $v0, 4
	la $a0, msg4				#se imprime el cuarto mensaje, ya acabados los 10 segundos.
	syscall
	
	li $v0, 32				#se "duerme" el programa durante 30 segundos.
	li $a0, 30000
	syscall
	
	j regresar				#se devuelve a regresar para poner el pulsador en 0, imprimir el primer mensaje y entrar en el ciclo esperando de nuevo que cambie el pulsador.

	.ktext 0x80000180			#direccion a donde se van las interrupciones.

	handler:
	addi $sp, $sp, -24			#guardar el contexto.
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $v0, 16($sp)
	sw $a0, 20($sp)
	
	.set noat
	move $k0, $at
	.set at
	
	li $t0, 0xffff0004			#se recibe desde el teclado un caracter.
	lb $t1, 0($t0)
	
	li $t2, 115				#pregunta si es igual al codigo assci de "s".
	bne $t1, $t2, fin
	
	la $t3, pulsador			#si es igual, cambia el pulsador a 1 y sale, si no deja el pulsador en 0.
	li $t0, 1
	sw $t0, 0($t3)
	
	fin:					#se restaura el contexto.
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $v0, 16($sp)
	lw $a0, 20($sp)
	
	.set noat
	move $at, $k0
	.set at
	eret
	
	
	
	
	
