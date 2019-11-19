.eqv BMP_FILE_SIZE 3200000  #maksymalny rozmair pliku
.data 

.align 4 #wyrówanujemy do 32
res:	.space 2
image:	.space BMP_FILE_SIZE
width:	.word 0
height:	.word 0
padding:.word 0 
extra:.word 0	
fname:	.asciiz "pep.bmp" #nazwa pliku
count_of_loop:	.word 25 #liczba iteracji ciągu

	.text
	.globl main
main:
# ============================================================================	
read_bmp:
#open file
	sub $sp, $sp, 4		#zmienne lokalne.
	sw $s1, 4($sp)
	
	li $v0, 13		#open file
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignorujemy
        syscall
	move $s1, $v0      # zapisujemy file descriptor
	
#read file
	li $v0, 14		#read file
	move $a0, $s1		#w s1 jest file descriptor
	la $a1, image		#sdres input buffer
	li $a2, BMP_FILE_SIZE	#maximum number characters to read
	syscall

#close file
	li $v0, 16		#close file
	move $a0, $s1		#w s1 file descriptor
        syscall
	
	lw $s1, 4($sp)		#zdejmujemy ze stosu s1
	add $sp, $sp, 4
	
# ============================================================================	
#określamy wysokość i długość na podstawie bitmpay
	la $t0, image + 14	#adres na poczatek pixel array
	li $v0, 1
	lw $a0, ($t0)
	syscall #wywoła w konsoli
	li $s1, 0
	li $s2, 0
	
	la $t7, image + 18 #width
	lw $t3, ($t7)
	sw $t3, width
	
	la $t7, image + 22 # height
	lw $t4, ($t7)
	sw $t4, height
	
	andi $t3, $t3, 3 # $s5 holds number of padding pixels
	sw $t3,	padding
# ============================================================================	
#ustawiamy jednorodny kolor obrazkay	
loop:					
	move	$a0, $s1		#x
	move	$a1, $s2		#y
	li 	$a2, 0x000000FF	#color - 00RRGGBB		

# ============================================================================	
put_green:
#ustawiamy konkretne kolory pixela
#$a0 - x 
#$a1 - y  - (0,0) - lewy dolny róg
#$a2 - 0RGB - kolor pixela
	
	sub $sp, $sp, 4		#odkładamy  t1
	sw $t1, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t2
	sw $t2, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t3
	sw $t3, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t4
	sw $t4, 4($sp)
	
	la $t1, image + 10	#adres pod jakim zaczynają się pixele w file header
	lw $t2, ($t1)		#wartosc pod jaka znajduja się  pixele w bmp
	la $t1, image		#adres bitmapy
	add $t2, $t1, $t2	#ładuej adres pierwszego pixela zdjęcia
	
	#liczmy adres pixela
	la $t3, image + 18
	lw $t4, ($t3)
	lw $s6, extra
	
#color:
	add $t3, $t4, $t4
	add $t4, $t4, $t3
	mul $t1, $a1, $t4 #w a1 jest zapisana wartsc y 
	move $t3, $a0		
	sll $a0, $a0, 1	#przesuniecie do green (ominięcie none i alpha)
	add $t3, $t3, $a0	#załadowanie do t3 adresu juz do greena 
	add $t1, $t1, $t3	#przesuniecie na y
	add $t2, $t2, $t1
	#sll $s6, $s6, 1	#adres pixela
	add $t2, $t2, $s6
	srl $a0, $a0, 1 

	#ustawiamy nowy kolor
	sb $a2,($t2) 		#odkłądamy niebieski
	srl $a2,$a2,8
	sb $a2,1($t2)		#odkłądamy zielony
	srl $a2,$a2,8
	sb $a2,2($t2)		#odkłądamy czerwony
	
	lw $t4, 4($sp)		#zdejmujemy zmienne lokalne
	add $sp, $sp, 4
	
	lw $t3, 4($sp)		
	add $sp, $sp, 4
	
	lw $t2, 4($sp)		
	add $sp, $sp, 4
	
	lw $t1, 4($sp)		
	add $sp, $sp, 4
	
# ============================================================================
#koniec ustawiania pixela
	addi	$s1, $s1, 1
	lw	$s3, width
	ble	$s1, $s3, loop
	lw 	$s7,extra
	lw 	$s6,padding
	add	$s7,$s7, $s6
	sw	$s7, extra
	addi	$s2, $s2,1
	li 	$s1, 0
	lw	$s3, height
	ble	$s2, $s3, loop
	
# ============================================================================	
#save blue
save_color:
#funkcja zapisująca bitmape
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
	

# ============================================================================	
#określamy wartośći początkowe	
	li $t0, 0	#x
	li $t1, 0	#y
	li $t2,	0	#licznik
	
	
	
	lw $s0, count_of_loop

# ============================================================================	
#wyliczamy krok x i y oraz promien zbieżności 		
init:
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
	lw 	$s7,extra
	move	$s7,$zero
	sw	$s7, extra
# ============================================================================	
#wyliczamy wartosci dla kolejnych pixeli		
set_loop:
	move $t3, $s4 
	mul $t3, $t3, $t1 #y+krok
	add $t3, $t3, $s1 #y+min_y
	move $t8, $t3 #zapamietujemy do poznijeszych obiczen
	
	move $t4, $s2 
	mul $t4, $t4, $t0 #x+krok
	add $t4, $t4, $s1 #x+min_x
	move $t9, $t4 #zapamietujemy do poznijeszych obiczen
# ============================================================================	
#pętla iteracyjna	
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
# ============================================================================	
get_color:
	move	$a0, $t0		#x
	move	$a1, $t1		#y
	li 	$a2, 0x00000000	#kolor - 00RRGGBB	
	beq	$t2, $s0, put_pixel
	mul	$s6, $t2, 0xFF
	div 	$s6, $s0
	mflo	$s6
	add	$a2, $s6, $a2 
# ============================================================================
put_pixel:
#ustawiamy konkretne kolory pixela
#$a0 - x 
#$a1 - y  - (0,0) - lewy dolny róg
#$a2 - 0RGB - kolor pixela
	
	sub $sp, $sp, 4		#odkładamy  t1
	sw $t1, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t2
	sw $t2, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t3
	sw $t3, 4($sp)
	
	sub $sp, $sp, 4		#odkładamy  t4
	sw $t4, 4($sp)
	
	la $t1, image + 10	#adres pod jakim zaczynają się pixele w file header
	lw $t2, ($t1)		#wartosc pod jaka znajduja się  pixele w bmp
	la $t1, image		#adres bitmapy
	add $t2, $t1, $t2	#ładuej adres pierwszego pixela zdjęcia
	
	#liczmy adres pixela
	la $t3, image + 18
	lw $t4, ($t3)
	lw $s6, extra
	
#color:
	add $t3, $t4, $t4
	add $t4, $t4, $t3
	mul $t1, $a1, $t4 #w a1 jest zapisana wartsc y 
	move $t3, $a0		
	sll $a0, $a0, 1	#przesuniecie do green (ominięcie none i alpha)
	add $t3, $t3, $a0	#załadowanie do t3 adresu juz do greena 
	add $t1, $t1, $t3	#przesuniecie na y
	add $t2, $t2, $t1
	#sll $s6, $s6, 1	#adres pixela
	add $t2, $t2, $s6
	srl $a0, $a0, 1 

	#ustawiamy nowy kolor
	sb $a2,($t2) 		#odkłądamy niebieski
	srl $a2,$a2,8
	sb $a2,1($t2)		#odkłądamy zielony
	srl $a2,$a2,8
	sb $a2,2($t2)		#odkłądamy czerwony
	
	lw $t4, 4($sp)		#zdejmujemy zmienne lokalne
	add $sp, $sp, 4
	
	lw $t3, 4($sp)		
	add $sp, $sp, 4
	
	lw $t2, 4($sp)		
	add $sp, $sp, 4
	
	lw $t1, 4($sp)		
	add $sp, $sp, 4
	
# ============================================================================
	move 	$t2, $zero
	addi	$t0, $t0, 1
	lw	$s6, width
	
	ble	$t0, $s6, set_loop #x<width
	lw 	$s6,padding
	lw 	$s7,extra
	add 	$s7, $s7, $s6
	sw	$s7, extra
	add	$t1, $t1, 1
	move 	$t0, $zero
	lw	$s6, height
	ble	$t1, $s6, set_loop #y<height
# ============================================================================
save_picture:
#funkcja zapisująca bitmape
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
	
	
exit: 	li $v0,10		#zamykamy program
	syscall

# ============================================================================	
	
