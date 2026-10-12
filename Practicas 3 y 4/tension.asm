.data
	TensionControl: .word 0
	TensionEstado: .word 0
	TensionSistol: .word 39
	TensionDiastol: .word 45
	salto_linea: .asciiz "\n"
	tensionSistol: .asciiz "tension sistolica:"
	tensionDiastol: .asciiz "tension diastolica:"
.text
	jal InicializarMedicionTension
	jal LeerTension
	move $t0, $v0
	move $t1, $v1
	
	la $a0, tensionSistol
	li $v0, 4
	syscall
	
	move $a0, $t0
	li $v0, 1
	syscall
	
	la $a0, salto_linea
	li $v0, 4
	syscall
	
	la $a0, tensionDiastol
	li $v0, 4
	syscall
	
	move $a0, $t1
	li $v0, 1
	syscall
	
	li $v0, 10
	syscall
	
	InicializarMedicionTension:
	li $t0, 1
	sw $t0, TensionControl
	li $t1, 1
	ciclo:
	lw $t3, TensionEstado
	beq $t1, $t3, finciclo
	j ciclo
	finciclo:
	jr $ra
	
	LeerTension:
	lw $t1, TensionSistol
	lw $t2, TensionDiastol
	move $v0, $t1
	move $v1, $t2
	jr $ra