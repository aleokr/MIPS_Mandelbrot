.eqv BMP_FILE_SIZE 3200000  #rozmiar pliku
.eqv BYTES_PER_ROW 600  
.data 

.align 4 #wyrówanujemy do 32
res:	.space 2
image:	.space BMP_FILE_SIZE
width:	.word 0
height:	.word 0
padding:.word 0 	
fname:	.asciiz "01.bmp" #nazwa pliku
count_of_loop:	.word 15

	.text
main:
	jal read_bmp	
	la $t0, image + 14	#adres do pixel array w bitmapie
	li $v0, 1
	lw $a0, ($t0)
	syscall #wywoła w konsoli
	li $s1, 0
	li $s2, 0
	
	la $t7, image + 18 # image width
	lw $t3, ($t7)
	sw $t3, width
	
	la $t7, image + 22 # image height
	lw $t4, ($t7)
	sw $t4, height
	
loop:					#ustawiamy jednolity kolor obrazka
	move	$a0, $s1		#x
	move	$a1, $s2		#y
	li 	$a2, 0x000000FF	#color - 00RRGGBB		
	jal	put_pixel
	addi	$s1, $s1, 1
	lw	$s3, width
	ble	$s1, $s3, loop
	addi	$s2, $s2,1
	li 	$s1, 0
	lw	$s3, height
	ble	$s2, $s3, loop
	
	jal save_bmp
	
	li $t0, 0	#x
	li $t1, 0	#y
	li $t2,	0	#licznik
	
	and $t5, $t3, 3 # $s5 padding
	sw $t5,	padding
	
	lw $s0, count_of_loop
	
make_set:
	# kwadrat 2x2
	li $s1, -2 # $43 minimalna wartosc na osiach
	sll $s1, $s1, 24
	li $s2, 4 # $t4 maksymalna wartosc na X
	sll $s2, $s2, 24
	lw $s3, width
	div $s2, $s2, $s3 # krok X------
	
	li $s4, 4
	sll $s4, $s4, 24 # $t6 maksymalna wartosc na Y
	lw $s3, height
	div $s4, $s4, $s3 # krok Y
	
	li $s5, 4 #zbiór jest zbieżny gdy x^2+y^2<4
	sll $s5, $s5, 24
	
set_loop:
	move $t3, $s4 
	mul $t3, $t3, $t1 #y+krok
	add $t3, $t3, $s1 #y+min_y
	move $t8, $t3 #zapamietujemy do poznijeszych obiczen
	
	move $t4, $s2 
	mul $t4, $t4, $t0 #x+krok
	add $t4, $t4, $s1 #x+min_x
	move $t9, $t4 #zapamietujemy do poznijeszych obiczen
	
repeat:
	#CZESC RZECZYWISTA
	mul $t5, $t4, $t4 #x^2
	mfhi $s6
	sll $s6, $s6, 8
	srl $t5, $t5, 24
	or $t5, $s6, $t5
	
	mul $t6, $t3, $t3 #y^2
	mfhi $s6
	sll $s6, $s6, 8
	srl $t6, $t6, 24
	or $t6, $s6, $t6
	
	sub $t7, $t5, $t6 #x^2-y^2
	add $t7, $t7, $t9
	
	#CZESC UROJONA
	mul $t5, $t4, $t3
	mfhi $s6
	sll $s6, $s6, 8
	srl $t5, $t5, 24
	or $t5, $s6, $t5
	sll $t5, $t5, 1
	add $t5, $t5, $t8
	
	move $t4, $t7
	move $t3, $t5 #przypisujemy nowe wartosci x i y , nowe x i nowe y znajduje się w t7 i t5
	
	#liczymy wartosc modułu
	mul $t7, $t7, $t7
	mfhi $s6
	sll $s6, $s6, 8
	srl $t7, $t7, 24
	or $t7, $s6, $t7
	
	mul $t5, $t5, $t5
	mfhi $s6
	sll $s6, $s6, 8
	srl $t5, $t5, 24
	or $t5, $s6, $t5
	
	add $t6, $t7, $t5 #z_n
	
	add $t2, $t2, 1 #counter++
	
	bgt $t6, $s5, get_color #modul >2
	blt $t2, $s0, repeat
	
get_color:
	move	$a0, $t0		#x
	move	$a1, $t1		#y
	li 	$a2, 0x00000000	#kolor - 00RRGGBB	
	beq	$t2, $s0, set_color
	mul	$s6, $t2, 255
	div 	$s6, $s0
	mflo	$s6
	add	$a2, $s6, $a2 
	
set_color:	
		
	jal	put_pixel
	move 	$t2, $zero
	addi	$t0, $t0, 1
	lw	$s6, width
	#mul	$s6, $s6, 3
	ble	$t0, $s6, set_loop #x<width
	add	$t1, $t1, 1
	li 	$t0, 0
	lw	$s6, height
	#mul	$s6, $s6, 3
	ble	$t1, $s6, set_loop

	
	jal save_bmp
	
exit: 	li $v0,10		#koniec programy
	syscall

# ============================================================================
read_bmp:

	sub $sp, $sp, 4		
	sw $ra,4($sp)		#odkładamy adres powrotu 
	sub $sp, $sp, 4		#odkładamy na stos zmienne lokalne
	sw $s1, 4($sp)
#open file	
	li $v0, 13		#open file
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignorujemy
        syscall
	move $s1, $v0      # zapisujemy file descriptor

#read file
	li $v0, 14		#read file
	move $a0, $s1		#w s1 jest file descriptor
	la $a1, image		#adress of input buffer
	li $a2, BMP_FILE_SIZE	#maximum number characters to read
	syscall

#close file
	li $v0, 16		#close file
	move $a0, $s1		#w s1 file descriptor
        syscall
	
	lw $s1, 4($sp)		#zdejmujemy ze stosu s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#zdejmujemy adres powrotu
	add $sp, $sp, 4
	jr $ra			#i wracamy 

# ============================================================================
save_bmp:

	sub $sp, $sp, 4		#odkładamy adres powrotu
	sw $ra,4($sp)
	sub $sp, $sp, 4		#zmienna lokalna
	sw $s1, 4($sp)
#open file
	li $v0, 13		#open file
        la $a0, fname		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignorujemy
        syscall
	move $s1, $v0      # zapisujemy file descriptor

#save file
	li $v0, 15		#save file
	move $a0, $s1		#file descriptor
	la $a1, image		#output buffer
	li $a2, BMP_FILE_SIZE	#max of characters to write
	syscall

#close file
	li $v0, 16		#close file
	move $a0, $s1		#file descriptor
        syscall
	
	lw $s1, 4($sp)		#zdejmujemy ze stosu
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================
put_pixel:

#	$a0 - x 
#	$a1 - y - (0,0) - lewy dolny róg
#	$a2 - 0RGB - pixel kolor


	sub $sp, $sp, 4		#push $ra 
	sw $ra,4($sp)
	
	sub $sp, $sp, 4		#push t1
	sw $t1, 4($sp)
	
	sub $sp, $sp, 4		#push t2
	sw $t2, 4($sp)
	
	sub $sp, $sp, 4		#push t3
	sw $t3, 4($sp)
	
	sub $sp, $sp, 4		#push t4
	sw $t4, 4($sp)
	
	la $t1, image + 10	# adres pod jakim zaczynają się pixele w file header
	lw $t2, ($t1)		#wartosc pod jaka znajduja się  pixele w bmp
	la $t1, image		#adres bitmapy
	add $t2, $t1, $t2	#ładuej adres pierwszego pixela zdjęcia
	
	#obliczanie pixela
	la $t3, image + 18
	lw $t4, ($t3)
	mul $t4, $t4, 3
	mul $t1, $a1, $t4 #w a1 jest zapisana wartsc y 
	move $t3, $a0		
	sll $a0, $a0, 1	#przesuniecie do green (ominięcie none i alpha)
	add $t3, $t3, $a0	#załadowanie do t3 adresu juz do greena 
	add $t1, $t1, $t3	# przesuniecie na y
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2) 		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R
	
	lw $t4, 4($sp)		#pop t4
	add $sp, $sp, 4
	
	lw $t3, 4($sp)		#pop t3
	add $sp, $sp, 4
	
	lw $t2, 4($sp)		#pop t2
	add $sp, $sp, 4
	
	lw $t1, 4($sp)		#pop t1
	add $sp, $sp, 4
	
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================
	