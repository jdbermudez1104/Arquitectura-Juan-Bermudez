.data 
	mensaje: .asciiz "ingrese un numero: "
	mensaje2: .ascii "el resultado es: "

.text 
main:
  li $v0,4
  la $a0,mensaje
  syscall
  
  li $v0,5
  syscall
  move $s0,$v0
  
  paridad_interna:
  li $t0,0
  li $t1,0
  
  for:
  beq $t1, $s0, imprimir
  li $t2,1
  sub $t0,$t2,$t0
  addi $t1,$t1,1
  j for
  
  imprimir:
  la $a0,mensaje2
  li $v0,4
  syscall
  
  move $a0,$t0
  li $v0,1
  syscall
  
  li $v0,10
  syscall
