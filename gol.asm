    ;;    game state memory location
    .equ CURR_STATE, 0x1000              ; current game state
    .equ GSA_ID, 0x1004                  ; gsa currently in use for drawing
    .equ PAUSE, 0x1008                   ; is the game paused or running
    .equ SPEED, 0x100C                   ; game speed
    .equ CURR_STEP,  0x1010              ; game current step
    .equ SEED, 0x1014                    ; game seed
    .equ GSA0, 0x1018                    ; GSA0 starting address
    .equ GSA1, 0x1038                    ; GSA1 starting address
    .equ SEVEN_SEGS, 0x1198              ; 7-segment display addresses
    .equ CUSTOM_VAR_START, 0x1200        ; Free range of addresses for custom variable definition
    .equ CUSTOM_VAR_END, 0x1300
    .equ LEDS, 0x2000                    ; LED address
    .equ RANDOM_NUM, 0x2010              ; Random number generator address
    .equ BUTTONS, 0x2030                 ; Buttons addresses

    ;; states
    .equ INIT, 0
    .equ RAND, 1
    .equ RUN, 2

    ;; constants
    .equ N_SEEDS, 4
    .equ N_GSA_LINES, 8
    .equ N_GSA_COLUMNS, 12
    .equ MAX_SPEED, 10
    .equ MIN_SPEED, 1
    .equ PAUSED, 0x00
    .equ RUNNING, 0x01

main:
    ;; TODO


; BEGIN:clear_leds
clear_leds: ;; no arguments/ no return values
	addi t1, zero, LEDS ; store leds in a register to use it
	stw zero, 0(t1) ; store zeros in LED[0]
	addi t0, t1, 4; address of LED[1]
	stw zero, 0(t0); store zeros in LED[1]
	addi t0, t0, 4; address of LED[2]
	stw zero, 0(t0); store zeros in LED[2]
	ret ; return empty 

; END:clear_leds






; BEGIN:set_pixel
set_pixel:
	;; arguments a0(x-coord) a1(y-coord)
	cmpgeui t0, a0, 4 ; checking if the x coord is ≥ 4
	cmpgeui t1, a0, 8 ; checking if the x coord is ≥ 8
	addi t6, zero, 1 ; Initialize a var to 1
	addi t7, zero, LEDS ; store leds in register to use it	
	bne t6, t0 , LEDS0 ; branch to label leds 0 if x coord < 4
	bne t6, t1, LEDS1 ; branch to label leds1 if x-coord < 8
	
	;if x ≥ 8 :
	ldw t3, 8(t7) ; load LEDS[2] -> 3nd word
	slli t5, t6, 3 ;  = 8
	sub a0, a0, t5 ; x - 8 (will be non negative because x≥8)
	slli t0, a0, 3 ; multiply x coord by 8
	add t0, t0, a1 ; add 5 to so you get 8x + y
	sll t2, t6, t0 ; shift the bit initialized to 1 to match the pos of the bit we are trying to change
	or t3, t3, t2 ; modify the selected bit
	stw t3, 8(t7) ; store modified word back at LEDS[2]
	ret ;return empty
	
LEDS0:
	ldw t3, 0(t7)
	slli t0, a0, 3 ; multiply x coord by 8
	add t0, t0, a1 ; add 5 to so you get 8x + y
	sll t2, t6, t0 ; shift the bit initialized to 1 to match the pos of the bit we are trying to change
	or t3, t3, t2 ; modify the selected bit
	stw t3, 0(t7) ; store modified word back
	ret ; return empty
LEDS1:
	ldw t3, 4(t7) ; load LEDS[1] -> 2nd word
	slli t5, t6, 2 ;  = 4
	sub a0, a0, t5 ; x - 4 (will be non negative because x≥4)
	slli t0, a0, 3 ; multiply x coord by 8
	add t0, t0, a1 ; add 5 to so you get 8x + y
	sll t2, t6, t0 ; shift the bit initialized to 1 to match the pos of the bit we are trying to change
	or t3, t3, t2 ; modify the selected bit
	stw t3, 0x4(t7) ; store modified word back at LEDS[1]
	ret ; return empty
	
	
; END:set_pixel





; BEGIN:wait
wait: ;; no arguments /no return values
	addi t1, zero, 1 ; initializing var to 1
	slli t0, t1, 19 ; multiplying it by 2^19
loop: ;starting the loop
	sub t0, t0, t1 ; decrement counter by 1
	bne zero,t0, loop ; branch to loop if counter not equal to 0
	ret ; return empty
; END:wait





; BEGIN:get_gsa
get_gsa: ;; argument a0(y coord for gsa line 0≤y≤7) / return v0(gsa line at y coord)
	addi t0, zero, 1 ; init var to 1
	addi t2 , zero, GSA_ID ; store gsa id in a register to use it
	slli t1, a0, 2 ; multiply y by 4
	beq t2, t0, get_1 ; branch if gsa 1 is the current
	
get_0: ;if gsa_0 is the curr then gsa_1 is the next
	ldw v0, GSA1(t1) ; load the gsa at line y into v0 from gsa_1
	ret 


get_1: ; if gsa_1 is the current then gsa_0 is the next
	ldw v0, GSA0(t1) ; load the gsa at line y into v0 from gsa_0
	ret

; END:get_gsa





; BEGIN:set_gsa
set_gsa: ;;arguments a0(GSA line), a1(y-coord to insert line at)/ return none
	addi t0, zero, 1 ; init var to 1
	addi t2 , zero, GSA_ID ; store gsa id in a register to use it
	slli t1, a1, 2 ; multiply y by 4
	beq t2, t0, set_1 ; branch if gsa 1 is the current
	
set_0: ;if gsa_0 is the curr then gsa_1 is the next
	stw a0, GSA1(t1) ; store the line at coord y in gsa_1
	ret 

set_1: ; if gsa_1 is the current then gsa_0 is the next
	stw a0, GSA0(t1) ; store the line at coord y in gsa_0
	ret	
; END:set_gsa




	
; BEGIN:draw_gsa
draw_gsa: ;; arguments none / return none
	addi t0, zero, 1 ; init var to 1
	addi t5, zero, 1 ; constant 1 (model for comparison)
	add t1, zero, zero ; init var to 0 (counter for y coord)
	add t3, zero,zero ; counter for x coord
	addi t2 , zero, GSA_ID ; store gsa id in a register to use it QUESTION: GSA_ID is NOT immediate value tho
	beq t2, t0, draw_1_y ; branch if gsa 1 is the current


	;; if the current gsa is 0
draw_0_y: ; draw GSA 1 y coord
	add a0, t1, zero ; y coord to get gsa
	addi t1, t1, 1 ; increment t1 by 1
	call get_gsa ; gets the gsa at line a0 from gsa 1
	add t3, zero,zero ;reinitialize x coord to 0
	add t4, v0, zero ; store the gsa line into a var

draw_0_x: ; draw each bit in the line at coord y
	add a1, a0, zero ; y coord to set pixel
	add a0, t3, zero ; x coord to set pixel
	addi t3, t3, 1 ; add one to x counter
	and t0, t4, t5 ; if the selected bit is 1 or not
	slli t5, t5, 1 ; shift the model bit by 1 to the left to check with next bit
	beq t0, zero, draw_0_x ; if the bit pointed at in the gsa line is 0 than go to the next bit
	call set_pixel ;set pixel at coord x,y
	cmpeqi t6, t3, N_GSA_COLUMNS ; if the max x coord has been attained
	beq t6, zero, draw_0_x ; if the max x coord hasn't been attained start the loop again for x
	cmplti t7, t1, N_GSA_LINES; if the max y coord hasn't been attained
	beq t7, t6, draw_0_y ;if there's no more significant bits in the line but there is still other lines to go to
	ret


	;; if the current gsa is 1
draw_1_y: ; draw GSA 1 y coord
	add a0, t1, zero ; y coord to get gsa
	addi t1, t1, 1 ; increment t1 by 1
	call get_gsa ; gets the gsa at line a0 from gsa 1
	add t3, zero,zero ;reinitialize x coord to 0
	add t4, v0, zero ; store the gsa line into a var

draw_1_x: ; draw each bit in the line at coord y
	add a1, a0, zero ; y coord to set pixel
	add a0, t3, zero ; x coord to set pixel
	addi t3, t3, 1 ; add one to x counter
	and t0, t4, t5 ; if the selected bit is 1 or not
	slli t5, t5, 1 ; shift th emodel bit by 1 to the left to check with next bit
	beq t0, zero, draw_1_x ; if the bit pointed at in the gsa line is 0 than go to the next bit
	call set_pixel ;set pixel at coord x,y
	cmpeqi t6, t3, N_GSA_COLUMNS; if the max x coord has been attained
	beq t6, zero, draw_1_x; if the max x coord hasn't been attained start the loop again for x
	cmplti t7, t1, N_GSA_LINES; if the max y coord hasn't been attained
	beq t7, t6, draw_1_y ;if there's no more significant bits in the line but there is still other lines to go to
	ret

; END:draw_gsa



; BEGIN:random_gsa
random_gsa: ;;arguments none / return none
	addi t5, zero, 1 ; set t5 to 1
	addi t4, zero, GSA_ID ; get current GSA ID
	addi t6, zero, 32
	beq t4, t5, random_gsa1

random:
	ldw t0, RANDOM_NUM(zero)
	sub t6, t6, t5 ; t6 - 1
	addi t2, zero, 1 ; create constant t2
	and t1, t2, t0 ; and operation to get last bit
	andi t3, t1, 1 ; mod 2 operation, t3 is the generated 0/1
	cmpnei t3, t3, 1 ; if t3=0, then set the value to 1
	slli t7, t7, 1 ; shift left
	or t7, t7, t3 ; store t3 at this last bit
	bne t6, zero, random_gsa1 ; do while all 32 random bits are generated


random_gsa1:
	br random
	stw t7, LEDS(zero) ; store the random bits to LED0
	br random
	stw t7, LEDS+4(zero) ; store the random bits to LED1
	br random
	stw t7, LEDS+8(zero) ; ; store the random bits to LED0 --REMARQUE-- : or store at the GSA directly? Or should I reload these to a GSA?

	
; END:random_gsa




; BEGIN:change_speed
change_speed: ;;arguments register a0: 0 if increment, 1 if decrement /return none
	ldw t0, SPEED(zero) ; take the current game speed in t0
	add t1, zero, a0 ; set t1 to val of a0
	addi t2, zero, 1 ; set t2 to 1
	beq t1, zero, increment_speed ; if t1 = 0 then go to increment 
	beq t1, t2, decrement_speed ; if t1 = 1 then go to decrement

increment_speed:
	cmplti t3, t0, MAX_SPEED ; set t3 to 1 if current speed < MAX_SPEED else 0
	add t0, t0, t3 ; add current speed and t3
	stw t0, SPEED(zero)
	ret ; QUESTION: can I 'ret' to simply end change_speed? aka not go to decrement_speed

decrement_speed:
	cmpgei t4, t0, 2 ; set t4 to 1 if current speed ≥ 2 else 0
	sub t0, t0, t4 ; sub current speed and t4
	stw t0, SPEED(zero)
	ret
	
; END:change_speed


; BEGIN:pause_game
pause_game: ;;arguments none /return none
	addi t0, zero, PAUSE ; set t0 to current PAUSE value
	cmpeqi t1, t0, 0 ; set t1 to 1 if PAUSE is 0
	stw t1, PAUSE(zero) ; store t1 at PAUSE

; END:pause_game	


; BEGIN:change_steps
change_steps: ;;arguments register a0,a1,a2  /return none
	addi t5, zero, CURR_STEP ; store CURR_STEP
	cmpeqi t0, a0, 1
	cmpeqi t1, a1, 1
	cmpeqi t2, a2, 1

	;curr_step = curr_step + 16^2*t + 16^1*t1 + 16^0*t0 

;for b2 0000........ b1 ....0000.... b0........0000
; END:change_steps	



; BEGIN:increment_seed
increment_seed: ;;arguments none / return none
	addi t0, zero, CURR_STATE ; set t0 to current game state
	cmpeqi t1, t0, INIT ; set t1 to 1 if curr_state = INIT
	add t0, t0, t1 ; add t1 to current state
	stw t0, CURR_STATE(zero) ; put value to CURR_STATE

; END:increment_seed	


; ; BEGIN:update_state
; update_state: ;;arguments register a0: edgecapture  / return none
; 	add t0, zero, a0 ; set t0 to a0's value
; 	addi t5, zero 1 ; set t5 to constant 1
; 	addi t2, zero, 1 ; create mask 00...1
; 	andi t1, t2, t0 ; and operation to get t0's last bit
; 	beq t1, t5, init_state ; if last button is pressed, go to init
; 	beq 

; init_state:
; 	add t4, zero, INIT
; 	stw t4, CURR_STATE(zero) ; store INIT to CURR_STATE
; 	//call reset_game


; ; END:update_state

; BEGIN:select_action:
select_action:
	addi t0, zero, CURR_STATE
	cmpeqi t1, t0, INIT




font_data:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9
    .word 0xEE ; A
    .word 0x3E ; B
    .word 0x9C ; C
    .word 0x7A ; D
    .word 0x9E ; E
    .word 0x8E ; F

seed0:
    .word 0xC00
    .word 0xC00
    .word 0x000
    .word 0x060
    .word 0x0A0
    .word 0x0C6
    .word 0x006
    .word 0x000

seed1:
    .word 0x000
    .word 0x000
    .word 0x05C
    .word 0x040
    .word 0x240
    .word 0x200
    .word 0x20E
    .word 0x000

seed2:
    .word 0x000
    .word 0x010
    .word 0x020
    .word 0x038
    .word 0x000
    .word 0x000
    .word 0x000
    .word 0x000

seed3:
    .word 0x000
    .word 0x000
    .word 0x090
    .word 0x008
    .word 0x088
    .word 0x078
    .word 0x000
    .word 0x000

    ;; Predefined seeds
SEEDS:
    .word seed0
    .word seed1
    .word seed2
    .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

MASKS:
    .word mask0
    .word mask1
    .word mask2
    .word mask3
    .word mask4
