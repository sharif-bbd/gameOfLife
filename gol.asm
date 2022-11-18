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
	stw a0, GSA1(t1) ; load the gsa at line y into v0 from gsa_1
	ret 

set_1: ; if gsa_1 is the current then gsa_0 is the next
	stw a0, GSA0(t1) ; load the gsa at line y into v0 from gsa_0
	ret	
; END:set_gsa

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
