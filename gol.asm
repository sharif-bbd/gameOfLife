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

	addi sp, zero, 0x1300
	addi t0, zero, 0 ; 000000000000
	add a0, zero, t0
	addi a1, zero, 0
	call set_gsa
	addi t1, zero, 28 ; 000000011100
	add a0, zero, t1
	addi a1, zero, 1
	call set_gsa
	addi t2, zero, 100 ; 000001100100
	add a0, zero, t2
	addi a1, zero, 2
	call set_gsa
	addi t3, zero, 812 ; 001100101100
	add a0, zero, t3
	addi a1, zero, 3
	call set_gsa
	addi t4, zero, 1248 ; 010011100000
	add a0, zero, t4
	addi a1, zero, 4
	call set_gsa
	addi t5, zero, 1540 ; 011000000100
	add a0, zero, t5
	addi a1, zero, 5
	call set_gsa
	addi t6, zero, 4 ; 000000000100
	add a0, zero, t6
	addi a1, zero, 6
	call set_gsa
	addi t7, zero, 4 ; 000000000100
	add a0, zero, t7
	addi a1, zero, 7
	call set_gsa

	; call draw_gsa
	
	; call update_gsa
	; call draw_gsa
	addi a0, zero, 2
	addi a1, zero, 1
	call find_neighbours
	


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
	addi sp, zero, 0x1300 ; init stack pointer to the stack bottom TODO: check si c'est ici
	
	addi sp, sp, -4 ; decrement stack pointer by 4
	stw ra, 0(sp) ; store return address from main procedure

	call clear_leds ; clear all the leds before drawing

	

	addi t0, zero, 1 ; init var to 1
	
	add t1, zero, zero ; init var to 0 (counter for y coord)
	add t3, zero,zero ; counter for x coord


draw_y: ; draw GSA 1 y coord
	add a0, t1, zero ; y coord to get gsa
	addi t1, t1, 1 ; increment t1 by 1
	addi t5, zero, 1 ; constant 1 (model for comparison)

	addi sp, sp, -4 ; decrement stack pointer by 4
	stw t1, 0(sp) ; store the y counter in the stack	

	call get_gsa ; gets the gsa at line a0 from gsa 1

	add t3, zero,zero ;reinitialize x coord to 0
	add t4, v0, zero ; store the gsa line into a var
	add a1, a0, zero ; y coord to set pixel	

draw_x: ; draw each bit in the line at coord y
	
	add a0, t3, zero ; x coord to set pixel
	addi t3, t3, 1 ; add one to x counter
	
	addi sp, sp, -4 ; move stack pointer to make space for a new wod
	stw t3, 0(sp) ; push x counter to stack	

	and t0, t4, t5 ; if the selected bit is 1 or not
	slli t5, t5, 1 ; shift the model bit by 1 to the left to check with next bit
	
	addi sp, sp, -4 ; push model for comparison in stack because $t5 is modified in set pixel
	stw t5, 0(sp)
	
	call set_if_1 ; outside procedure that will set the pixel if it is 1 in the gsa

	ldw t5, 0(sp) ; pop back comparison value from stack
	addi sp, sp, 4

	ldw t3, 0(sp) ; load x counter from stack
	addi sp, sp, 4 ; move stack pointer to up 1 spot

	cmpeqi t6, t3, N_GSA_COLUMNS ; if the max x coord has been attained
	beq t6, zero, draw_x ; if the max x coord hasn't been attained start the loop again for x
	
	ldw t1, 0(sp) ; pop y counter from stack
	addi sp, sp, 4 ; move stack pointer up 1 spot

	cmplti t7, t1, N_GSA_LINES ; if the max y coord hasn't been attained
	beq t7, t6, draw_y ;if there's no more significant bits in the line but there is still other lines to go to
	
	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	
	ret



set_if_1:
	bne t0, zero, set_pixel
	ret


; END:draw_gsa







; BEGIN:random_gsa
random_gsa: ;  initialize the current GSA to a random state.
;;arguments none / return none

	addi sp, sp, -4 ; decrement stack pointer by 4
	stw ra, 0(sp) ; store return address from main procedure
	addi t5, zero, 1 ; set t5 to constant 1
	;addi t4, zero, GSA_ID ; get current GSA ID 
	addi t6, zero, 31 ; set t6 to 31 for counter
	add t7, zero, zero ; set t7 empty register
	addi t4, zero, 0 ; set counter to 0
	call loop_random
	

loop_random:

	call randomizer ;
	add a0, zero, t7 ; store generated t7 at the argument for set_gsa
	add a1, zero, t4 ; store 0 for arguemnt for set_gsa
	call set_gsa ; set gsa line 0 to this random element generated

	addi t6, zero, 31 ; set t6 to 31 for counter
	add t7, zero, zero ; set t7 empty register
	addi t2, zero, 1 ; set t2 to constant 8 TODO: change the 1 to 8 later, it was just for testing
	addi t4, t4, 1 ; increment counter
	bne t4, t2, loop_random ; loop if not all 8 lines are generated yet
	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	
	ret

randomizer:
	ldw t0, RANDOM_NUM(zero) ; load random number from memory
	sub t6, t6, t5 ; decrement counter
	and t1, t5, t0 ; and operation to get last bit
	andi t3, t1, 1 ; mod 2 operation, t3 is the generated 0/1
	slli t7, t7, 1 ; shift left
	or t7, t7, t3 ; store t3 at this last bit 
	bne t6, zero, randomizer ; do while all 32 random bits are generated
	ret ; go back to random_gsa when generating random line finished
	
; END:random_gsa



; BEGIN:change_speed
change_speed: ;;arguments register a0: 0 if increment, 1 if decrement /return none
	ldw t0, SPEED(zero) ; take the current game speed in t0
	; add t1, zero, a0 ; set t1 to val of a0
	addi t2, zero, 1 ; set t2 to constant 1
	beq a0, zero, increment_speed ; if t1 = 0 then go to increment 
	beq a0, t2, decrement_speed ; if t1 = 1 then go to decrement

increment_speed:
	cmplti t3, t0, MAX_SPEED ; set t3 to 1 if current speed < MAX_SPEED else 0
	add t0, t0, t3 ; add current speed and t3
	stw t0, SPEED(zero) ; store computed speed to SPEED
	ret

decrement_speed:
	cmpgei t4, t0, 2 ; set t4 to 1 if current speed ≥ 2 else 0
	sub t0, t0, t4 ; sub current speed and t4
	stw t0, SPEED(zero) ; store computed speed to SPEED
	ret
	
; END:change_speed


; BEGIN:pause_game
pause_game: ;;arguments none /return none
	ldw t3, PAUSE(zero) ; load current PAUSE value
	add t0, zero, t3 ; set t0 to current PAUSE value
	cmpeqi t1, t0, 0 ; set t1 to 1 if PAUSE is 0
	stw t1, PAUSE(zero) ; store t1 at PAUSE
	ret

; END:pause_game	


; BEGIN:change_steps
change_steps: ;;arguments register a0(units), a1(tens), a2(hundreds) / return none

	ldw t3, CURR_STEP(zero) ; load CURR_STEP value
	add t5, zero, t3 ; store CURR_STEP to t5

	add t0, zero, zero ; initialize empty register
	or t0, t0, a2 ; store a2(hundreds) value
	slli t0, t0, 4 ; shift 4
	or t0, t0, a1 ; store a1(tens) value
	slli t0, t0, 4 ; shift 4
	or t0, t0, a0 ; store a0(units) value
	add t5, t5, t0 ; add CURR_STEP and the input values

	stw t5, CURR_STEP(zero) ; store computed value to CURR_STEP

	ret

; END:change_steps	



; BEGIN:increment_seed
increment_seed: ;;arguments none / return none
	addi sp, sp, -4 ; decrement stack pointer by 4
	stw ra, 0(sp) ; store return address from main procedure
	ldw t0, CURR_STATE(zero) ; load current state to t0
	addi t1, zero, INIT
	addi t2, zero, RAND
	beq t0, t1, init_increment
	beq t0, t2, rand_increment

init_increment:
	ldw t1, SEED(zero) ; load current SEED 
	addi t3, zero, 3 ; set t3 to constant 3
	addi t4, zero, 4 ; set t4 to constant 4
	beq t1, t3, init_increment_3 ; cf. edstream
	beq t1, t4, init_increment_4 ; cf. edstream
	addi t1, t1, 1 ; increment game seed by 1
	stw t1, SEED(zero); store incremented seed to SEED
	call mask ; QUESTION&TODOthis will take charge in copying this seed to current GSA right?
	
	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	ret

init_increment_3:
	addi t1, t1, 1 ; increment by 1
	stw t1, SEED(zero) ; store incremented seed to SEED
	call random_gsa
	
	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	ret

init_increment_4:
	call random_gsa

	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	ret

rand_increment:
	call random_gsa

	ldw ra, 0(sp) ; retreive return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	ret

; END:increment_seed	


; BEGIN:update_state
update_state: ;;arguments register a0: edgecapture  / return none
	ldw t0, CURR_STATE(zero) ; load current state
	addi t1, zero, INIT ; set t1 to INIT value
	addi t2, zero, RAND ; set t2 to RAN value
	addi t3, zero, RUN ; set t3 to RUN value
	beq t0, t1, init_state_change ; if current state is INIT then go to init_state_change
	beq t0, t2, rand_state_change ; if current state is RAND then go to rand_state_change
	beq t0, t3, run_state_change ; if current state is RUN then go to run_state_change


init_state_change:
	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	;and t0, t5, t6 ; mask and get b0 
	ldw t0, SEED(zero) ; set t0 to the current value of SEED
	
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored
	; correct way to get a0's val? How can be b0 = N if it is only 0/1 => store variable SEED nb, increment everytime b0 is pressed.


	cmplti t7, t0, N_SEEDS ; check if b0 < N, t7=1 if true
	addi t5, zero, N_SEEDS ; register for N_SEEDS
	;beq t2, t6, init_set_state ; go to INIT if b2=1
	;beq t3, t6, init_set_state ; go to INIT if b3=1 QUESTION: if same state, still renew state or discard?
	;beq t4, t6, init_set_state ; go to INIT if b4=1
	;beq t7, t6, init_set_state ; go to INIT if b0 < N
	beq t0, t5, rand_set_state ; go to RAND if b0=N_SEEDS
	beq t1, t6, run_set_state ; go to RUN if b1=1
	

rand_state_change:
	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	;and t0, t5, t6 ; mask and get b0 
	ldw t0, SEED(zero) ; set t0 to the current value of SEED
	
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored

	;beq t0, t6, rand_set_state ; go to RAND if b0=1
	;beq t2, t6, rand_set_state ; go to RAND if b2=1
	;beq t3, t6, rand_set_state ; go to RAND if b3=1
	;beq t4, t6, rand_set_state ; go to RAND if b4=1
	beq t1, t6, run_set_state ; go to RUN if b1=1


run_state_change:
	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	;and t0, t5, t6 ; mask and get b0 
	ldw t0, SEED(zero) ; set t0 to the current value of SEED
	
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored

	;beq t0, t6, run_set_state ; go to RUN if b0=1
	;beq t1, t6, run_set_state ; go to RUN if b1=1
	;beq t2, t6, run_set_state ; go to RUN if b2=1
	;beq t4, t6, run_set_state ; go to RUN if b4=1
	beq t3, t6, init_set_state ; go to INIT if b3=1


init_set_state:
	addi t0, zero, INIT ; set t0 to INIT
	stw t0, CURR_STATE(zero) ; store INIT in CURR_STATE
	call reset_game ; QUESTION: here jump or call?

rand_set_state:
	addi t0, zero, RAND ; set t0 to RAND
	stw t0, CURR_STATE(zero) ; store RAND in CURR_STATE
	ret

run_set_state:
	addi t0, zero, RUN ; set t0 to RUN
	stw t0, CURR_STATE(zero) ; store RUN in CURR_STATE
	ret

; END:update_state



; BEGIN:select_action:
select_action: ;; arguments register a0: a copy of the edgecapture register / return none
	ldw t0, CURR_STATE(zero) ; load current state
	addi t5, zero, 1 ; constant 1
	cmpeqi t1, t0, INIT ; set t1=1 if CURR_STATE=INIT
	beq t1, t5, init_select_action ; go to init_select_action if STATE=INIT
	cmpeqi t2, t0, RAND ; set t2=1 if CURR_STATE=RAND
	beq t2, t5, rand_select_action ; go to rand_select_action if STATE=RAND
	cmpeqi t3, t0, RUN ; set t3=1 if CURR_STATE=RUN
	beq t3, t5, run_select_action ; go to run_select_action if STATE=RUN


init_select_action:
	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	and t0, t5, t6 ; mask and get b0
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored

	beq t0, t6, increment_seed ; generate new GSA
	;beq t1, t6, update_state ; go to RUN
	beq t2, t6, change_steps ; if button 2 is pressed, change steps
	beq t3, t6, change_steps ; if button 3 is pressed, change steps
	beq t4, t6, change_steps ; if button 4 is pressed, change steps
	ret

rand_select_action:

	add t0, zero, zero ; initialize registers to 0
	add t1, zero, zero ; initialize registers to 0
	add t2, zero, zero ; initialize registers to 0
	add t3, zero, zero ; initialize registers to 0
	add t4, zero, zero ; initialize registers to 0

	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	and t0, t5, t6 ; mask and get b0
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored

	
	beq t0, t6, random_gsa ; generate new GSA
	;beq t1, t6, update_state ; go to RUN 
	beq t2, t6, change_steps ; if button 2 is pressed, change steps
	beq t3, t6, change_steps ; if button 3 is pressed, change steps
	beq t4, t6, change_steps ; if button 4 is pressed, change steps
	ret

run_select_action:
	add t0, zero, zero ; initialize registers to 0 
	add t1, zero, zero ; initialize registers to 0
	add t2, zero, zero ; initialize registers to 0
	add t3, zero, zero ; initialize registers to 0
	add t4, zero, zero ; initialize registers to 0

	add t5, zero, a0 ; copy a0
	addi t6, zero, 1 ; set constant 1
	and t0, t5, t6 ; mask and get b0
	srli t5, t5, 1 ; shift right by 1
	and t1, t5, t6 ; mask and get b1 
	srli t5, t5, 1 ; shift right by 1
	and t2, t5, t6 ; mask and get b2
	srli t5, t5, 1 ; shift right by 1
	and t3, t5, t6 ; mask and get b3
	srli t5, t5, 1 ; shift right by 1
	and t4, t5, t6 ; mask and get b4
	; value of b4 b3 b2 b1 b0 stored

	beq t0, t6, pause_game ; if button 0 pressed, call pause_game
	addi a0, zero, 0 ; set a0 to 0, increment
	; store return address
	beq t1, t6, change_speed ; if button 1 pressed,increment speed by 1
	;call t1, t6, change_speed ; if button 1 pressed,increment speed by 1

	addi a0, zero, 1 ; set a0 to 1, decrement
	beq t2, t6, change_speed ; if button 2 pressed, decrement speed by 1
	;beq t3, t6, reset_game ; if button 3 pressed, reset_game
	beq t4, t6, random_gsa ; if button 4 pressed, call random gsa
	ret


; END:select_action



; BEGIN:cell_fate
cell_fate: ;; a0: number of live neighbouring cells a1: examined cell state /return v0: 1 if the cell is alive 0 otherwise
	add t3, zero, a0 ; set t3 to nb of live neighbouring cells
	addi t4, zero, 1 ; set t4 to constant 1
	beq a1, t4, fate_alive
	beq a1, zero, fate_dead

fate_alive:
	add t1, zero, zero ; set t1 to 0
	;cmplti t1, t3, 2 ; [UNDERPOPULATION] set t1 to 1 if cell has strictly less than 2 neighbour
	;cmpeqi t1, t1, 0 ; invert result (cuz we want t1 to be 0 if strictly less than 2 neighbour)
	;cmpgei t1, t3, 4 ; [OVERPOPULATION] set t1 to 1 if cell has ≥4 neighbours
	;cmpeqi t1, t1, 0 ; invert result (cuz we want t1 to be 0 if strictly more than 3 neighbour) 
	cmpeqi t1, t3, 2 ; [STATIS] cell remains 1 if it has 2 neighbours
	cmpeqi t2, t3, 3 ; [STATIS] cell remains 1 if it has 3 neighbours
	or t1, t1, t2 ; set 1 if t1 or t2 true
	add v0, zero, t1 ; set v0 to t1's value
	ret

fate_dead:
	cmpeqi t2, t3, 3 ; check if nb of neighbours is exactly 3
	add v0, zero, t2 ; set v0 to t2's value 
	ret

; END:cell_fate


; BEGIN:find_neighbours
find_neighbours: ;; arguments: register a0: x coordinate of examined cell • register a1: y coordinate of examined cell
	


	addi sp, sp, -20 ; put sX and ra to stack
  	stw s0, 0 (sp)
  	stw s1, 4 (sp)
  	stw s2, 8 (sp)
	stw s3, 12 (sp)
  	stw ra, 16 (sp)

	add s0, zero, zero ; empty s0
	addi s1, zero, -1 ; set t0 to constant -1
	addi s2, zero, 1 ; set t0 to constant 1
	add s3, zero, zero ; set s3 empty

	addi t6, zero, 2 ; set t6 to constant 2

	call y_loop
	add v0, zero, s0 ; put nb neighbours s0 to v0

	ldw ra, 16 (sp) ; retrieve sX and ra to stack
	ldw s3, 12 (sp)
  	ldw s2, 8 (sp)
  	ldw s1, 4 (sp)
  	ldw s0, 0 (sp)
  	addi sp, sp, 20
	ret

y_loop:
	addi sp, sp, -4
	stw ra, 0 (sp) ; put ra to stack

	add s3, s1, a1 ; put current y coordinate+i to s3
	andi s3, s3, 7 ; modulo 8 operation
	addi sp, sp, -4
	stw a0, 0 (sp) ; put a0 to stack
	add a0, zero, s3 ; put current line coord. to a0
	call get_gsa
	add t3, zero, v0 ; get current gsa line
	addi t4, zero, -1 ; set t4 to constant -1
	ldw a0, 0 (sp) ; load a0 back
  	addi sp, sp, 4

	
	call x_loop

	ldw ra, 0 (sp) ; load ra back
  	addi sp, sp, 4

	addi s1, s1, 1 ; increment t0 by 1
	bne s1, t6, y_loop ; loop while line y+1 is computed
	ret

x_loop:
	addi sp, sp, -4
	stw ra, 0 (sp) ; put ra to stack

	add t5, a0, t4 ; t5 = x + j

	addi sp, sp, -4
	stw a0, 0 (sp) ; put a0 to stack

	add a0, zero, t5 ; pass t5 to argument to op_modulo
	call op_modulo

	ldw a0, 0 (sp) ; load a0 back
  	addi sp, sp, 4

	srl t0, t3, v0 ; shift right curent line t3 by x coord.
	and t7, s2, t0 ; and operation with 1 to see if the cell is alive or dead

	;check for cell_state
	cmpeqi t0, t4, 0 ; see if current j is 0
	cmpeqi t1, s1, 0 ; see if current y coord. is 0 
	add t0, t0, t1 ; add x and y coord.
	call cell_state_update
	;end check 

	ldw ra, 0 (sp) ; load ra back
  	addi sp, sp, 4

	add s0, s0, t7 ; increment s0 by 1 if neighbour cell is alive 

	addi t4, t4, 1 ; increment t4
	bne t4, t6, x_loop ; loop while cell x+1 is computed
	
	ret
	

op_modulo:

	add v0, zero, a0 ; pass the given x coord. by default
	addi t2, zero, 12 ; set t2 to 12
	blt v0, s1, return_eleven ; if given x coord. is -1, then return 11
	bge v0, t2, return_zero ; if given x coord. is 12, then return 0
	ret

return_eleven:
	addi v0, zero, 11 ; put 11 to return value
	ret

return_zero:
	addi v0, zero, 0 ; put 0 to return value
	ret
	
cell_state_update:
	cmpeqi t0, t0, 2 ; check if i=0 == true and j=0 == true
	and t7, t7, t0
	add v1, zero, t7 ; put 1 if examining cell is alive
	ret


; END:find_neighbours




		
; BEGIN:update_gsa
update_gsa: ;;arguments none /return none

ldw t0, PAUSED(zero) ; load value of PAUSED (0=game is paused)
addi t1, zero, 0 ; y coord. counter
bne t0, zero, update_row ; update gsa if paused != 0 
addi t6, zero, 8 ; constant 8
addi t7, zero, 12 ; constant 12
ldw t4, GSA_ID(zero) ; load current GSA_ID
cmpeqi t5, t4, 0 ; invert GSA_ID
ret


update_row:
	add t3, zero, zero ; initialize counter for col
	add t0, zero, zero ; empty register
	call update_col
	add a0, zero, t0 ; put the compuled col. to a0
	add a1, zero, t1
	call set_gsa
	addi t1, t1, 1
	bne t1, t6, update_row
	ret

update_col:
	
	add a1, zero, t1 ; current y coord.
	add a0, zero, t3 ; current x coord.
	call find_neighbours
	add a0, zero, v0 ; store find_neighbours's nb lining neighbours
	add a1, zero, v1 ; store find_neighbours's cell state
	call cell_fate
	sll t2, v0, t3 ; shift left the cell_fate value by x coord.
	or t0, zero, v0 ; or operation and put it in the register

	addi t3, t3, 1
	bne t3, t7, update_col
	ret


; END:update_gsa


; BEGIN:mask
mask: ;;arguments none / return none

	addi sp, sp, -4 ; decrement stack pointer by 4
	stw ra, 0(sp) ; store return address from main procedure

	ldw t0, SEED(zero) ; load current seed
	slli t0, t0, 2 ; multiply by 4
	ldw t7, MASKS(t0) ; get address of MASK[SEED]
	addi t4, zero, 8 ; constant 7
	addi t5, zero, 0 ; loop counter for line coord

loop_mask:
	ldw s0, 0(t7) ; get mask 0's line 0 at 's0'
	add a0, zero, t5 ; put y line coord. to a0
	call get_gsa
	add t1, zero, v0 ; store gsa line 0 at t1
	and t0, s0, t1 ; and operation mask and gsa line
	add a0, zero, t0 ; store masked line to a0
	add a1, zero, t5 ; store line coord.
	call set_gsa
	addi t5, t5, 1 ; update counter by 1
	addi t7, t7, 4 ; add 4 at line coord. to get address
	bne t4, t5, loop_mask
	
	ldw ra, 0(sp) ; retrieve return address to main procedure from stack
	addi sp, sp, 4 ; increment stack pointer by 4
	
	ret

; END:mask



; BEGIN:reset_game
reset_game: ;;arguments none /return none
	addi t0, zero, 1 ; constant 1
	stw t0, CURR_STEP(zero) ; 1. store 1 in CURR_STEP 
	stw t0, SEVEN_SEGS(zero) ; TODO: 7-seg display to 1 like this?
;	stw seed0, SEEDS(zero) ; TODO: store seeds
	stw zero, CURR_STATE(zero) ; set current game state to 0
	stw zero, GSA_ID(zero) ; set GSA_ID to zero
	stw t0, PAUSE(zero) ; set PAUSE to 1
	stw t0, SPEED(zero) ; set game speed to 1
	
; END:reset_game


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
