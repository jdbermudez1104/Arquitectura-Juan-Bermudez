.data
	LuzControl: .word 0
	LuzEstado: .word 1
	LuzDatos: .word 110
	salto_linea: .asciiz "\n"
	estado: .asciiz "estado:"
	luminosidad: .asciiz "luminosidad:"
.text
	jal InicializarSensorLuz
	move $a0, $v0
	jal LeerLuminosidad
	bne $v1, $zero, sigue
	move $t0, $v0
	
	la $a0, luminosidad
	li $v0, 4
	syscall
	
	move $a0, $t0
	li $v0, 1
	syscall
	
	la $a0, salto_linea
	li $v0, 4
	syscall
	
	sigue:
	la $a0, estado
	li $v0, 4
	syscall
	
	move $a0, $v1
	li $v0, 1
	syscall
	
	li $v0, 10
	syscall
	
	InicializarSensorLuz:
	li $t0, 1
	sw $t0, LuzControl
	li $t1, -1
	li $t2, 1
	ciclo:
	lw $t3, LuzEstado
	beq $t1, $t3, finciclo
	beq $t2, $t3, finciclo
	j ciclo
	finciclo:
	move $v0, $t3
	jr $ra
	
	LeerLuminosidad:
	li $t0, -1
	beq $a0, $t0, error
	lw $t1, LuzDatos
	bltz $t1, error
	li $t2, 1023
	bgt $t1, $t2, error
	move $v0, $t1
	li $v1, 0
	j fin
	error:
	li $v1, -1
	fin:
	jr $ra
	
	