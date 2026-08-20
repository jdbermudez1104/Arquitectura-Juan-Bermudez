.data 
	mensaje: .asciiz "ingrese un numero: "
	mensaje2: .ascii "el resultado es: "

.text 

main:
  la $a0,mensaje
  li $v0,4
  syscall
  
  li $v0,5
  syscall
  move $a0,$v0
    
  jal paridad
  move $t1,$v0
 
 
  la $a0,mensaje2
  li $v0,4
  syscall
  
  move $a0,$t1
  li $v0,1
  syscall
  
  li $v0,10
  syscall
  
    
paridad:

	beq $a0,$zero,caso_base
	
	addi $sp, $sp, -8 # abro espacio en la pila   
  	sw $ra, 0($sp) # guardo el retorno
  	sw $a0, 4($sp) # guarda el nuemor actual
	
	addi $a0, $a0, -1
	
	jal paridad
	
	li $t1, 1
	sub $v0, $t1, $v0
	
	lw $ra, 0($sp) #recupero los valores de la llamada actual
	lw $a0, 4($sp)
	addi $sp, $sp, 8 #devuelvo la pila
	jr $ra	

caso_base:

	li $v0, 0
	jr $ra
