	INCLUDE "VECTREX.I"
	ORG     $0000

user_ram        EQU     $c880
music_active    EQU     user_ram
menu_selected_option	equ	music_active + 2
morbCounter	equ	menu_selected_option + 1
lives	equ	morbCounter + 1
score	equ	lives + 1
empty	equ	score + 6
marcY	equ	score + 7
marcX	equ	marcY + 1
enemyY1	equ	marcX + 1
enemyX1	equ	enemyY1 + 1
enemyY2	equ	enemyX1 + 1
enemyX2	equ	enemyY2 + 1
marcVelocity	equ	enemyX2 + 1
enemy1VelocityX	equ	marcVelocity + 1
enemy1VelocityY	equ	enemy1VelocityX + 1
enemy2VelocityX	equ	enemy1VelocityY + 1
enemy2VelocityY	equ	enemy2VelocityX + 1
frenzyCounter	equ	enemy2VelocityY + 1
frenzy_active equ	frenzyCounter + 1
totalStuns	equ	frenzy_active + 1
totalKills	equ	totalStuns + 1
totalDeaths	equ	totalKills + 1
gameState	 equ	totalDeaths + 1
last_joy_y	equ	gameState + 1
directionFaced	equ	last_joy_y + 1
enemy_available1  EQU	directionFaced + 1
enemy_available2	equ	enemy_available1 + 1
liveBullet	equ	enemy_available2 + 1
bulletY	equ	liveBullet + 1
bulletX	equ	bulletY + 1
bulletVelocityY	equ	bulletX + 1
bulletVelocityX	equ	bulletVelocityY + 1
voxStart	EQU	bulletVelocityX + 1
deathTimer	equ	voxStart + 1
rotangle	equ	deathTimer + 1
rotated	equ	rotangle + 1

TITLE_TEXT_SIZE	EQU	$E470 ; HEIGTH, WIDTH (-14, 96)
NORMAL_TEXT_SIZE	EQU	$F160 ; HEIGTH, WIDTH (-14, 96)
CREDIT_TEXT_SIZE	EQU	$F355 ; HEIGTH, WIDTH (-14, 96)
SCREEN_BOTTOM    EQU  (lo(-$80))
SCREEN_LEFT      EQU  (lo(-$80))
SCREEN_RIGHT     EQU  (lo($7f))
BALL_SIZE        EQU (lo(5))
BALL_INIT_YPOS   EQU (lo($6a))
BALL_X_RIGHT     EQU (lo(SCREEN_RIGHT-BALL_SIZE-$3))
BALL_X_LEFT      EQU (lo(SCREEN_LEFT+$11))
PADDLE_INIT_YPOS EQU (lo(SCREEN_BOTTOM+($12)))
BULLETVELOCITY	EQU	6
VOX_DONE            EQU      1 
VOX_STARTED         EQU      2 
VOX_STARTING        EQU      3

; Required Init Block
; GCE is necessary

	FCB     $67,$20
	FCC     "GCE 2023"
	FCB     $80
	FDB     music1
	FDB     $f850
	FDB     $30b8
	FCC     "MOON KNIGHT"
	FCB     $80,$0

	jmp      start 

; Vec Vox routines
                    INCLUDE  "vecvox.i"                   ; VecVox output routines
;
; Speech strings
                    INCLUDE  "speechData.i"

start:
; main game loop
bootup_game:
	jsr	init_vars
	jsr	title_screen
	jsr	game_play
	jsr	gameOver
	bra	start

init_vars:
	jsr      vox_init                     ; VecVox: initialize variables 
	jsr	DP_to_D0
	direct	$D0
	lda	#1
	sta	Vec_Joy_Mux_1_X
	lda	#3
	sta	Vec_Joy_Mux_1_Y
	ldd	#$0
	sta	Vec_Joy_Mux_2_X
	sta	Vec_Joy_Mux_2_Y
	sta	menu_selected_option
	sta	music_active
	std	score
	sta	empty
	sta	marcY
	sta	marcX
	sta	enemyX1
	sta	enemyX2
	sta	gameState
	sta	last_joy_y
	sta	frenzyCounter
	sta	frenzy_active
	std	totalStuns
	std	totalKills
	sta	totalDeaths
	sta	enemy_available1
	sta	enemy_available2
	sta	morbCounter
	sta	directionFaced
	sta	liveBullet
	sta	bulletY
	sta	bulletX
	sta	rotangle
	lda	#3
	sta	marcVelocity
	lda	#3
	sta	lives
	lda	BULLETVELOCITY
	sta	bulletVelocityY
	sta	bulletVelocityX
	;sta	rotangle
	lda      #VOX_STARTING 
	sta      voxStart 
	lda	#50
	sta	enemyY1
	sta	enemyY2
	lda	#-25
	sta	enemyX2
	rts

title_screen:
	jsr	Read_Btns
	jsr	DP_to_C8
	direct	$C8
	ldd	#NORMAL_TEXT_SIZE
	std	Vec_Text_HW
	LDA	#$00
	sta	gameState
	LDA	#$01               ; load #1
	STA	Vec_Music_Flag     ; set this as marker for music start
	LDU	#music8            ; load a music structure
	STU	music_active

title_screen_loop:
	jsr	start_my_sound
	jsr Wait_Recal	;breaks lda
	jsr	DP_to_D0
	direct	$D0
	jsr Intensity_5F
	jsr	check_title_input
	jsr	check_selected_option
	jsr Do_Sound
	jsr Read_Btns
	cmpa	#$08
	lbeq	main_choice ;then checks the selected main menu choice, if 0 then start game, if 1 go credits
	ldu      #vData                 ; address of list 
                    LDA      #$30                          ; Text position relative Y 
                    LDB      #$20                        ; Text position relative X 
                    tfr      d,x                          ; in x position of list 
                    lda      #$40                         ; scale positioning 
                    ldb      #$45                         ; scale move in list 
                    jsr      draw_synced_list 
	jsr	Reset0Ref
	ldu	#title_start_string
	lda	#-$38
	ldb	#-$45
	jsr	Print_Str_d
	ldu	#title_credit_string
	jsr	Reset0Ref
	lda	#-$60
	ldb	#-$35
	jsr	Print_Str_d
	bra	title_screen_loop

check_selected_option:
	lda	#$01
	cmpa	menu_selected_option
	beq	draw_credit_icon
	bne	draw_start_icon

check_title_input:
	jsr	Joy_Digital
	jsr	DP_to_C8
	direct	$C8
     ldb	last_joy_y        ; only jump if last joy pos was zero
     lda	Vec_Joy_1_Y
     sta	last_joy_y        ; store this joystick position
	jsr	DP_to_D0
	direct	$D0
	cmpb	last_joy_y
     bne	zero_check       ; no joystick input available
	rts

zero_check:
	cmpb	#0
	beq	update_title_icon
	rts

update_title_icon:
	ldb	menu_selected_option
	eorb	#$01
	stb	menu_selected_option
	rts

main_choice:
	lda	menu_selected_option
	beq	leave_title ;enter gameplay if first option selected
	jsr	credits_screen ;jump to credits if second option selected
	lbra	title_screen ;return to title screen

leave_title:
	rts

draw_start_icon:
	ldu	#onet_string
	lda	#-$38
	ldb	#-$70
	jsr	Print_Str_d
	rts

draw_credit_icon:
	ldu	#twot_string
	lda	#-$60
	ldb	#-$70
	jsr	Print_Str_d
	rts

credits_screen:
	jsr	DP_to_C8
	direct	$C8
	ldd	#CREDIT_TEXT_SIZE
	std	Vec_Text_HW
	JSR	DP_to_C8           ; set DP...
	LDA	#$01
	sta	gameState
	lda	#$00
	sta	morbCounter
	STA	Vec_Music_Flag     ; set this as marker for music start
	LDU	#music3            ; load a music structure
	STU	music_active

credits_screen_loop:
	jsr	start_my_sound
	jsr Wait_Recal
	jsr Do_Sound
	jsr Read_Btns
	cmpa	#$02
	beq	check_morbius
done_morbius_check:
	cmpa	#$04
	beq	check_credit_button
	jsr Intensity_5F
	ldu	#credits_director_string
	lda	#$60
	ldb	#-$80
	jsr	Print_Str_d
	ldu	#credits_thanks_string
	lda	#$25
	ldb	#-$67
	jsr	Print_Str_d
	ldu	#credits_retro_string
	lda	#-$10
	ldb	#-$65
	jsr	Print_Str_d
	ldu	#credits_marvel_string
	lda	#-$39
	ldb	#-$53
	jsr	Print_Str_d
	bra	credits_screen_loop

check_morbius:
	jsr	DP_to_D0
	direct	$D0
	lda	#1
	adda	morbCounter
	sta	morbCounter
	jsr	enterMorb
	bra	done_morbius_check

enterMorb
	lda	#10
	cmpa	morbCounter
	beq	morbius_screen
	rts

check_credit_button:
	rts

; this screen is pretty morbin (not really)
morbius_screen:
	jsr	DP_to_C8
	direct	$C8
	ldd	#CREDIT_TEXT_SIZE
	std	Vec_Text_HW
	JSR	DP_to_C8           ; set DP...
	LDA	#$04               ; load #1
	sta	gameState
	lda	#VOX_STARTING 
	sta	voxStart 
	STA	Vec_Music_Flag     ; set this as marker for music start
	LDU	#music1            ; load a music structure
	STU	music_active

morbius_screen_loop:
	;jsr	DP_to_D0
	;direct	$D0
	lda      voxStart 
	cmpa     #VOX_STARTING 
	bne      noVoxStart 
	lda      #VOX_STARTED
	sta      voxStart
	ldx      #speechData2
	stx      vox_addr	;start vox
noVoxStart:
	jsr	start_my_sound
	jsr Wait_Recal
	jsr Do_Sound
	jsr Read_Btns
	cmpa	#$04
	beq	check_credit_button
	jsr	vox_speak
	jsr	Intensity_5F
	ldu      #vData4                 ; address of list 
	LDA      #$0                          ; Text position relative Y 
	LDB      #$5                        ; Text position relative X 
	tfr      d,x                          ; in x position of list 
	lda      #$60                         ; scale positioning 
	ldb      #$60                         ; scale move in list 
	jsr      draw_synced_list
	bra	morbius_screen_loop

game_play:
	jsr	DP_to_D0
	direct	$D0
	ldd	#CREDIT_TEXT_SIZE
	std	Vec_Text_HW
	lda	#02
	sta	gameState
	ldx	#score
	jsr	Clear_Score
	JSR	DP_to_C8           ; set DP...
	LDA	#$01               ; load #1
	STA	Vec_Music_Flag     ; set this as marker for music start
	LDU	#silence          ; load a music structure
	STU	music_active

game_play_loop:
	jsr	start_my_sound
	jsr Wait_Recal
	jsr Do_Sound
	jsr	drawPlayer
	jsr	drawBorders
	jsr	drawWeapon
	jsr	drawEnemy1
	jsr	drawEnemy2
	jsr	drawCollisions
	jsr	drawScore
	jsr	drawLives
	lda	#0
	cmpa	lives
	bne	game_play_loop
	rts
	bra	game_play_loop

drawPlayer:
	jsr	find_direction ;determine direction faced
	;jsr	Intensity_5F
	;lda	marcY
	;ldb	marcX
	;jsr	Moveto_d_7F
	jsr	Intensity_5F
                LDD     marcY
                JSR     Moveto_d_7F        ; move to rel position D and scale factor 7F
                ;LDX     #vData5
	jsr	check_direction ;get sprite from direction
                    LDA      marcY                          ; Text position relative Y 
                    LDB      marcX                        ; Text position relative X 
                    tfr      d,x                          ; in x position of list 
                    lda      #130                         ; scale positioning 
                    ldb      #$50                         ; scale move in list 
                    jsr      draw_synced_list
	;lda 	#17		; Number of vectors
	;ldb	#128		; Scaling
	;jsr	Mov_Draw_VL_ab

readjoystick
	jsr	Joy_Digital	; Reads joystick
	lda	Vec_Joy_1_X
	beq	xready
	bmi	lmove

rmove	lda	marcX
	cmpa	#119
	bgt	xready
	LDB	marcX
	ADDB	marcVelocity
	STB	marcX
	bra	xready

lmove 	lda	marcX
	cmpa	#-119
	blt	xready
	LDB	marcX
	subB	marcVelocity
	STB	marcX
	bra	xready

; check vertical joystick

xready	lda	Vec_Joy_1_Y
	beq	yready
	bmi	dmove

umove	lda	marcY
	cmpa	#121
	beq	yready
	bgt	blockedUp
	LDB	marcY
	ADDB	marcVelocity
	STB	marcY
	bra	yready

blockedUp:
	lda	#121
	sta	marcY

dmove	lda	marcY
	cmpa	#-111
	beq	yready
	blt	blockedDown
	LDB	marcY
	subB	marcVelocity
	STB	marcY
	bra	yready

blockedDown:
	lda	#-111
	sta	marcY
	
yready
	rts

find_direction:
	jsr	Joy_Digital
     lda	Vec_Joy_1_Y
	cmpa	#0
	bne	yesJoy
	lda	Vec_Joy_1_X
	cmpa	#0
	bne	yesJoy
	rts
yesJoy:
	lda	#0
	sta	directionFaced
	lda	Vec_Joy_1_Y
	cmpa	#0
	bgt	positiveY
	blt	negativeY
	beq	checkX
positiveY:
	ldb	#1
	addb	directionFaced
	stb	directionFaced
	bra	checkX
negativeY:
	ldb	#4
	addb	directionFaced
	stb	directionFaced
checkX:
	lda	Vec_Joy_1_X
	cmpa	#0
	bgt	positiveX
	blt	negativeX
	beq	directionDone
positiveX:
	ldb	#2
	addb	directionFaced
	stb	directionFaced
	bra	directionDone
negativeX:
	ldb	#7
	addb	directionFaced
	stb	directionFaced
directionDone:
	rts

check_direction:
	lda	directionFaced
	cmpa	#1
	bls	up
	cmpa	#2
	beq	right
	cmpa	#3
	beq	ur
	cmpa	#4
	beq	down
	cmpa	#6
	beq	dr
	cmpa	#7
	beq	left
	cmpa	#8
	beq	ul
	cmpa	#11
	ldu	#marcFaceDL ;bottom left
	rts

up:
	ldu	#marcFaceU
	rts

right:
	ldu	#marcFaceR
	rts

ur:
	ldu	#marcFaceUR
	rts

down:
	ldu	#marcFaceD
	rts

dr:
	ldu	#marcFaceDR
	rts

left:
	ldu	#marcFaceL
	rts

ul:
	ldu	#marcFaceUL
	rts

drawBorders:
	jsr	Reset0Ref	
	jsr	Intensity_5F
	lda	#0		; Y
	ldb	#0		; X
	jsr	Moveto_d_7F	
	ldx	#borders		; Drawing the edges
	lda 	#8		; Vectors
	ldb	#128		; Scaling
	jsr	Mov_Draw_VL_ab
	rts

drawWeapon:
	jsr Read_Btns
	cmpa	#$08
	bne	noInput
	jsr	createBullet
noInput:
	lda	liveBullet
	cmpa	#1
	beq	bulletExists
	rts
bulletExists:
                ; now we change the y position
no_y_waitbullet:
                LDB     bulletY
                ADDB    bulletVelocityY
                STB     bulletY
y_change_donebullet:
                ; now we change the x position
no_x_waitbullet:
                LDB     bulletX
                ADDB    bulletVelocityX
                STB     bulletX
x_change_donebullet:
                ; now we check borders
                LDA     bulletVelocityX       ; in what direction is the ball moving?
                BMI     check_leftbullet         ; negative, than we check left border
                CMPB    #BALL_X_RIGHT      ; ball right out of bounds?
                BLE     x_right_okbullet
			lda	#0
			sta	liveBullet
check_leftbullet:
                CMPB    #BALL_X_LEFT       ; ball left out of bounds?
                BGE     x_left_okbullet
			lda	#0
			sta	liveBullet
x_left_okbullet:
x_right_okbullet:
                LDA     bulletVelocityY
                BPL     check_for_upper_borderbullet
                ; now we check if bottom
			  LDB     bulletY
                CMPB    #-120
                BGE     nothing_happensbullet
                ;LDA     #PADDLE_INIT_YPOS
                ;STA     bulletY
			lda	#0
			sta	liveBullet
check_for_upper_borderbullet:
; now we check if we are at the upper border
                LDB     bulletY
                CMPB    #121
                BLE     nothing_happensbullet
                ;LDA     #BALL_INIT_YPOS
                ;STA     bulletY
			lda	#0
			sta	liveBullet
nothing_happensbullet:
draw_ball_on_screenbullet:
                JSR     Reset0Ref
                LDD     bulletY
                JSR     Moveto_d_7F        ; move to rel position D and scale factor 7F
                LDX     #ball
                JSR     Draw_VLc
                RTS

createBullet:
	lda	#1
	sta	liveBullet
	lda	marcY
	sta	bulletY
	lda	marcX
	sta	bulletX
	lda	directionFaced
	cmpa	#1
	bls	upBullet
	cmpa	#2
	beq	rightBullet
	cmpa	#3
	beq	urBullet
	cmpa	#4
	beq	downBullet
	cmpa	#6
	beq	drBullet
	cmpa	#7
	beq	leftBullet
	cmpa	#8
	beq	ulBullet
	cmpa	#11
	ldx	#turtle_line_list
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

upBullet:
	ldx	#alus
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#0
	sta	bulletVelocityX
	rts

rightBullet:
	ldx	#alus
	lda	#0
	sta	bulletVelocityY
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

urBullet:
	ldx	#turtle_line_list
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

downBullet:
	ldx	#alus
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#0
	sta	bulletVelocityX
	rts

drBullet:
	ldx	#turtle_line_list
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

leftBullet:
	ldx	#alus
	lda	#0
	sta	bulletVelocityY
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

ulBullet:
	ldx	#turtle_line_list
	lda	#1*BULLETVELOCITY
	sta	bulletVelocityY
	lda	#-1*BULLETVELOCITY
	sta	bulletVelocityX
	rts

drawEnemy1:
                LDA     enemy_available1     ; check if there is an enemy
                CMPA    #0
                BNE     ball_is_available  ; if not
                JSR     get_new_ball       ; get a new enemy
ball_is_available:
                ; now we change the y position
no_y_wait:
                LDB     enemyY1
                ADDB    enemy1VelocityY
                STB     enemyY1
y_change_done:
                ; now we change the x position
no_x_wait:
                LDB     enemyX1
                ADDB    enemy1VelocityX
                STB     enemyX1
x_change_done:
                ; now we check if the ball bounces off a wall
                LDA     enemy1VelocityX ; check direction then border
                BMI     check_left
                CMPB    #BALL_X_RIGHT
                BLE     x_right_ok
                NEG     enemy1VelocityX       ; reflect direction
check_left:
                CMPB    #BALL_X_LEFT
                BGE     x_left_ok
                NEG     enemy1VelocityX       ; reflect direction
x_left_ok:
x_right_ok:
                LDA     enemy1VelocityY       ; checking for Y
                BPL     check_for_upper_border
                ; now we check if bottom
			  LDB     enemyY1
                CMPB    #PADDLE_INIT_YPOS
                BGE     nothing_happens
			lda	#0
			cmpa	enemy1VelocityX
			bne	notStunned1
			sta	enemy_available1
			sta	frenzy_active
			sta	frenzyCounter
			bra	check_for_upper_border ;remove orange eye status
notStunned1:
                ;LDA     #PADDLE_INIT_YPOS    ; otherwise use init position
                ;STA     enemyY1
                NEG     enemy1VelocityY       ; reflect direction
check_for_upper_border:
; now we check if we are at the upper border
                LDB     enemyY1
                CMPB    #BALL_INIT_YPOS
                BLE     nothing_happens
                ;LDA     #BALL_INIT_YPOS    ; otherwise use init position
                ;STA     enemyY1
                NEG     enemy1VelocityY       ; reflect direction
nothing_happens:
draw_ball_on_screen:
                JSR     Reset0Ref
	jsr	Intensity_3F
                LDD     enemyY1
                JSR     Moveto_d_7F        ; move to rel position D and scale factor 7F
                ;LDX     #vData5
	ldu      #vData5                 ; address of list 
                    LDA      enemyY1                          ; Text position relative Y 
                    LDB      enemyX1                        ; Text position relative X 
                    tfr      d,x                          ; in x position of list 
                    lda      #130                         ; scale positioning 
                    ldb      #$50                         ; scale move in list 
                    jsr      draw_synced_list
                ;JSR     Draw_VLc
                RTS

get_new_ball:
                LDA     #1              ; create enemy
                STA     enemy_available1
                LDA     #BALL_INIT_YPOS    ; start at top of screen
                STA     enemyY1
                LDA     #-2                ; ball y speed, negativ, since ball must move down
				suba	frenzy_active
                STA     enemy1VelocityY ; velocityY changes if frenzy
	jsr     Random     ; get random and decrease size to reasonable amount
	anda    #($7F)
	suba	#40
	sta	enemyX1
positiv_x:
				ldb	#3
                STB     enemy1VelocityX
                RTS

drawEnemy2:
	lda     enemy_available2     ; check if there is an enemy
	cmpa    #0
	bne     ball_is_available2
	jsr     get_new_ball2       ; spawn a new enemy
ball_is_available2:
                ; now we change the y position
no_y_wait2:
	ldb     enemyY2
	addb    enemy2VelocityY
	stb     enemyY2
y_change_done2:
                ; now we change the x position
no_x_wait2:
	ldb     enemyX2
	addb    enemy2VelocityX
	stb     enemyX2
x_change_done2:
                ; now we check if the ball bounces off a wall
	lda     enemy2VelocityX       ; check direction of ball and check border
	bmi     check_left2
	cmpb    #BALL_X_RIGHT      ; ball right out of bounds?
	ble     x_right_ok2         ;
	neg     enemy2VelocityX       ; yes, than change direction
check_left2:
	cmpb    #BALL_X_LEFT       ; ball left out of bounds?
	bge     x_left_ok2
	neg     enemy2VelocityX       ; reflect direction
x_left_ok2:
x_right_ok2:
	lda     enemy2VelocityY
	BPL     check_for_upper_border2
                ; now we check if bottom
	ldb     enemyY2
	cmpb    #PADDLE_INIT_YPOS
	bge     nothing_happens2
	lda	#0
	cmpa	enemy2VelocityX
	bne	notStunned2
	sta	enemy_available2
	;sta	frenzy_active
	;sta	frenzyCounter
	bra	check_for_upper_border2 ;remove orange eye status
notStunned2:
	;lda     #PADDLE_INIT_YPOS
	;sta     enemyY2
	neg     enemy2VelocityY       ; and reflect, using opposite y speed
check_for_upper_border2:
; now we check if we are at the upper border
	ldb     enemyY2
	cmpb    #BALL_INIT_YPOS
	ble     nothing_happens2
	;lda     #BALL_INIT_YPOS    ; use init position
	;sta     enemyY2
	neg     enemy2VelocityY       ; reflect direction
nothing_happens2:
draw_ball_on_screen2:
	jsr     Reset0Ref
	jsr	Intensity_3F
	;ldd	enemyY2
	;jsr     Moveto_d_7F        ; move to rel position D and scale factor 7F
	ldu      #vData5                 ; address of list 
                    LDA      enemyY2                          ; Text position relative Y 
                    LDB      enemyX2                        ; Text position relative X 
                    tfr      d,x                          ; in x position of list 
                    lda      #130                         ; scale positioning 
                    ldb      #$50                         ; scale move in list 
                    jsr      draw_synced_list
	rts

get_new_ball2:
	lda     #1              ; create enemy
	sta     enemy_available2
	lda     #BALL_INIT_YPOS    ; start at top of screen
	sta     enemyY2
	lda     #-3   ; ball y speed, negativ, since ball must move down
	suba	frenzy_active
	sta     enemy2VelocityY       ; velocityY changes if frenzy
	jsr     Random             ; get random and decrease size to reasonable amount
	anda    #($7F)
	suba	#30
	sta	enemyX2
positiv_x2:
	ldb	#-2
	stb     enemy2VelocityX       ; now store the speed
	rts

drawCollisions:
	ldx	marcY
	ldy	enemyY1
	lda	#10 ; (Height of object #1 + Height of object #2)/2
	ldb	#11 ; (Width of object #1 + Width of object #2)/2
	jsr	Obj_Hit
	bcc	enemy2stuff ; Branch if no collision
	lda	#0
	cmpa	enemy1VelocityX
	beq	alreadyStunnedMarc1 ;already stunned
	jsr	PlayerDeath
	rts
alreadyStunnedMarc1:
	sta	enemy_available1
	inc	frenzyCounter ; orange eyes
	inc	totalKills
	lda #4
	cmpa frenzyCounter
	bne	noFrenzy
	lda	#1
	sta	frenzy_active
	lda	#0
	sta	enemy_available2
	lda	#200
	ldx	#score
	ldb	#3
	cmpb	lives
	beq	doneEnemy1Score
	inc	lives
	bra	doneEnemy1Score
noFrenzy:
	lda	#100
	ldx	#score
doneEnemy1Score
	jsr	Add_Score_a
enemy2stuff:
	ldx	marcY
	ldy	enemyY2
	lda	#10 ; (Height of object #1 + Height of object #2)/2
	ldb	#11 ; (Width of object #1 + Width of object #2)/2
	jsr	Obj_Hit
	bcc	bulletColl1 ; Branch if no collision
	lda	#0
	cmpa	enemy2VelocityX
	beq	alreadyStunnedMarc2 ;already stunned
	jsr PlayerDeath
	rts
alreadyStunnedMarc2:
	sta	enemy_available2
	inc	frenzyCounter ; orange eyes
	inc	totalKills
	lda #4
	cmpa frenzyCounter
	bne	noFrenzy2
	lda	#1
	sta	frenzy_active
	lda	#0
	sta	enemy_available1
	lda	#200
	ldx	#score
	ldb	#3
	cmpb	lives
	beq	doneEnemy2Score
	inc	lives
	bra	doneEnemy2Score
noFrenzy2:
	lda	#100
	ldx	#score
doneEnemy2Score
	jsr	Add_Score_a ; done checking enemy2 and marc stuff
bulletColl1:
	lda	#0
	cmpa	liveBullet
	beq	alldone
	ldx	bulletY
	ldy	enemyY1
	lda	#10
	ldb	#10
	jsr	Obj_Hit
	bcc	bulletColl2 ; if no collision, check enemy 2
	lda	#0
	cmpa	enemy1VelocityX
	beq	alreadyStunnedBullet1 ;already stunned
	sta	enemy1VelocityX
	lda	#-1
	sta	enemy1VelocityY
	inc	totalStuns
	lda	#20
	ldx	#score
	jsr	Add_Score_a
alreadyStunnedBullet1:
	lda	#0
	sta	liveBullet
bulletColl2:
	lda	#0
	cmpa	liveBullet
	beq	alldone
	ldx	bulletY
	ldy	enemyY2
	lda	#10
	ldb	#10
	jsr	Obj_Hit
	bcc	alldone ; we done if no collision
	lda	#0
	cmpa	enemy2VelocityX
	beq	alreadyStunnedBullet2 ;already stunned
	sta	enemy2VelocityX
	lda	#-1
	sta	enemy2VelocityY
	inc	totalStuns
	lda	#20
	ldx	#score
	jsr	Add_Score_a
alreadyStunnedBullet2:
	lda	#0
	sta	liveBullet
alldone:
	rts

PlayerDeath:
	lda	#0
	sta	liveBullet
	sta	frenzy_active
	sta	frenzyCounter
	sta	enemy_available1
	sta	enemy_available2
	lda	#100
	sta	deathTimer
	jsr	deathAnim
	ldd	#0
	std	marcY
	sta	directionFaced
	dec lives
	inc	totalDeaths
	rts

deathAnim:
	jsr	start_my_sound
	jsr	Wait_Recal
	jsr Do_Sound
	jsr	drawBorders
	jsr	drawScore
	jsr	drawLives
	jsr	Intensity_5F ; Sets intensity to 127
; I tried to do a rotation here
; I dont know how to adapt it to synced lists
; so now im just putting death text
	jsr	Reset0Ref
	ldu	#dead_string
	lda	#30
	ldb	#-60
	jsr	Print_Str_d
	jsr	Reset0Ref
	ldu	#dead2_string
	lda	#-10
	ldb	#-70
	jsr	Print_Str_d
	;ldx vData7 ;ldx the sprite
	;ldb 	#12		; Number of vectors
	;lda	rotangle		; Scaling
	;ldu	#rotated
	;jsr	Rot_VL_ab
	;ldd	marcY
	;jsr	Moveto_d_7F
	;ldx	#rotated		; Drawing the rotation
	;lda 	#172		; Number of vectors
	;ldb	#128		; Scaling
	;jsr	Mov_Draw_VL_ab
	;LDA      marcY                          ; Text position relative Y 
                    ;LDB      marcX                        ; Text position relative X 
                    ;tfr      d,x                          ; in x position of list 
                    ;lda      #130                         ; scale positioning 
                    ;ldb      #$50                         ; scale move in list 
                    ;jsr      draw_synced_list
	dec	rotangle
	dec	deathTimer
	lda	deathTimer
	beq	animDone
	bra	deathAnim
animDone:
	rts

drawScore:
	jsr	Reset0Ref	
	jsr	Intensity_5F
	lda	#0
	ldb	#0
	jsr	Moveto_d_7F
	lda 	#110
	ldb	#30
	ldu	#score
	jsr	Print_Str_d
	rts

drawLives:
	jsr	Reset0Ref		
	lda	#3
	cmpa	lives
	beq	threeLives
	lda	#2
	cmpa	lives
	beq	twoLives
	ldu	#one_string
livesDrawn:
	lda 	#110
	ldb	#-120
	jsr	Print_Str_d
	rts

threeLives:
	ldu	#three_string
	bra	livesDrawn

twoLives:
	ldu	#two_string
	bra	livesDrawn

gameOver:
	jsr	DP_to_C8
	direct	$C8
	ldd	#CREDIT_TEXT_SIZE
	std	Vec_Text_HW
	JSR	DP_to_C8           ; set DP...
	LDA	#$03
	sta	gameState
	lda	#120
	sta	deathTimer
	lda	#VOX_STARTING
	sta	voxStart
	STA	Vec_Music_Flag     ; set this as marker for music start
	LDU	#silence            ; load a music structure
	STU	music_active

game_over_loop:
	lda	voxStart
	cmpa	#VOX_STARTING 
	bne	noVoxStart2
	lda	#VOX_STARTED
	sta	voxStart
	ldx	#speechData
	stx	vox_addr           ; start vox
noVoxStart2:
	jsr	start_my_sound
	jsr Wait_Recal
	jsr	DP_to_D0
	direct	$D0
	jsr Do_Sound
	jsr	Read_Btns
	jsr	vox_speak
	jsr Intensity_5F
	ldu      #vData3                 ; address of list 
                    LDA      #$0                          ; Text position relative Y 
                    LDB      #-$0                        ; Text position relative X 
                    tfr      d,x                          ; in x position of list 
                    lda      #$40                         ; scale positioning 
                    ldb      #$40                         ; scale move in list 
                    jsr      draw_synced_list
	jsr	Reset0Ref
	ldu	#gameover_string
	lda	#100
	ldb	#-$35
	jsr	Print_Str_d
	ldu	#rise_string
	lda	#-$160
	ldb	#-$75
	jsr	Print_Str_d
	dec	deathTimer
	lda	deathTimer
	beq	restartGame
	bra	game_over_loop
restartGame:
	rts

start_my_sound:
	JSR     DP_to_C8           ; set DP to C8
	lda	Vec_Music_Flag
	beq	continue_music
	LDU     music_active       ; get active music
	JSR     Init_Music_chk     ; and init new notes
	RTS

continue_music:
	lda	#$01
	sta Vec_Music_Flag
	rts

ZERO_DELAY          EQU      7

draw_synced_list: 
                    pshs     a                            ; remember out different scale factors 
                    pshs     b 
                                                          ; first list entry (first will be a sync + moveto_d, so we just stay here!) 
                    lda      ,u+                          ; this will be a "1" 
sync: 
                    deca                                  ; test if real sync - or end of list (2) 
                    bne      drawdone                     ; if end of list -> jump 
; zero integrators
                    ldb      #$CC                         ; zero the integrators 
                    stb      <VIA_cntl                    ; store zeroing values to cntl 
                    ldb      #ZERO_DELAY                  ; and wait for zeroing to be actually done 
; reset integrators
                    clr      <VIA_port_a                  ; reset integrator offset 
                    lda      #%10000010 
; wait that zeroing surely has the desired effect!
zeroLoop: 
                    sta      <VIA_port_b                  ; while waiting, zero offsets 
                    decb     
                    bne      zeroLoop 
                    inc      <VIA_port_b 
; unzero is done by moveto_d
                    lda      1,s                          ; scalefactor move 
                    sta      <VIA_t1_cnt_lo               ; to timer t1 (lo= 
                    tfr      x,d                          ; load our coordinates of "entry" of vectorlist 
                    jsr      Moveto_d                     ; move there 
                    lda      ,s                           ; scale factor vector 
                    sta      <VIA_t1_cnt_lo               ; to timer T1 (lo) 
moveTo: 
                    ldd      ,u++                         ; do our "internal" moveto d 
                    beq      nextListEntry                ; there was a move 0,0, if so 
                    jsr      Moveto_d 
nextListEntry: 
                    lda      ,u+                          ; load next "mode" byte 
                    beq      moveTo                       ; if 0, than we should move somewhere 
                    bpl      sync                         ; if still positive it is a 1 pr 2 _> goto sync 
; now we should draw a vector 
                    ldd      ,u++                         ;Get next coordinate pair 
                    STA      <VIA_port_a                  ;Send Y to A/D 
                    CLR      <VIA_port_b                  ;Enable mux 
                    LDA      #$ff                         ;Get pattern byte 
                    INC      <VIA_port_b                  ;Disable mux 
                    STB      <VIA_port_a                  ;Send X to A/D 
                    LDB      #$40                         ;B-reg = T1 interrupt bit 
                    CLR      <VIA_t1_cnt_hi               ;Clear T1H 
                    STA      <VIA_shift_reg               ;Store pattern in shift register 
setPatternLoop: 
                    BITB     <VIA_int_flags               ;Wait for T1 to time out 
                    beq      setPatternLoop               ; wait till line is finished 
                    CLR      <VIA_shift_reg               ; switch the light off (for sure) 
                    bra      nextListEntry 

drawdone: 
                    puls     d                            ; correct stack and go back 
                    rts

title_start_string:
	DB   "START GAME"
	DB   $80

dead_string:
	DB   "THE NIGHT"
	DB   $80

dead2_string:
	DB   "IS NOT OVER"
	DB   $80

title_credit_string:
	DB	"CREDITS"
	DB	$80

credits_director_string:
	DB	"DIRECTOR BILALSCAPE12"
	DB	$80

credits_thanks_string:
	DB	"SPECIAL THANKS TO"
	DB	$80

credits_marvel_string:
	DB	"MARVEL COMICS"
	DB	$80

credits_vec_string:
	DB	"ONLY FOR VECTREX"
	DB	$80

credits_retro_string:
	DB	"RETROACHIEVEMENTS"
	DB	$80

gameover_string:
	DB	"GAME OVER"
	DB	$80

rise_string:
	DB	"RISE AND LIVE AGAIN"
	DB	$80

onet_string:
	DB	"1."
	DB	$80

twot_string:
	DB	"2."
	DB	$80

one_string:
	DB	"L1"
	DB	$80

two_string:
	DB	"L2"
	DB	$80

three_string:
	DB	"L3"
	DB	$80

alus	fcb 	0,0		; Tip of the ship
				; also the 'hot spot'
	fcb	-3,2
	fcb	-3,1
	fcb	-2,0
	fcb	-3,1
	fcb	0,2
	fcb	-3,2
	fcb	0,-3
	fcb	2,-2
	fcb	0,-6
	fcb	-2,-2
	fcb	0,-3
	fcb	3,2
	fcb	0,2
	fcb	3,1
	fcb	2,0
	fcb	3,1
	fcb	3,2

borders:
	fcb	126,-126
	fcb	0,126
	fcb	0,126
	fcb	-126,0
	fcb	-126,0
	fcb	0,-126
	fcb	0,-126
	fcb	126,0
	fcb	126,0

ball:
                DB    3                    ; 4 vectors are drawn
                DB    0,   BALL_SIZE       ; next point relativ (y,x)
                DB   BALL_SIZE,    0       ; next point relativ (y,x)
                DB    0,  -BALL_SIZE       ; next point relativ (y,x)
                DB  -BALL_SIZE,    0       ; next point relativ (y,x)

silence:
                FDB     $fee8
        	FDB     $feb6
        FCB     $0,$80
        FCB     $0,$80

SPRITE_BLOW_UP EQU 25
turtle_line_list:
                DB 23                           ; number of vectors - 1
                DB  2*SPRITE_BLOW_UP,  2*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  2*SPRITE_BLOW_UP
                DB  2*SPRITE_BLOW_UP,  1*SPRITE_BLOW_UP
                DB  2*SPRITE_BLOW_UP, -2*SPRITE_BLOW_UP
                DB  0*SPRITE_BLOW_UP,  2*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  1*SPRITE_BLOW_UP
                DB  1*SPRITE_BLOW_UP,  3*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  4*SPRITE_BLOW_UP
                DB  1*SPRITE_BLOW_UP,  0*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  1*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  0*SPRITE_BLOW_UP
                DB -3*SPRITE_BLOW_UP,  2*SPRITE_BLOW_UP
                DB -3*SPRITE_BLOW_UP, -2*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP,  0*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP, -1*SPRITE_BLOW_UP
                DB  1*SPRITE_BLOW_UP,  0*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP, -4*SPRITE_BLOW_UP
                DB  1*SPRITE_BLOW_UP, -3*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP, -1*SPRITE_BLOW_UP
                DB  0*SPRITE_BLOW_UP, -2*SPRITE_BLOW_UP
                DB  2*SPRITE_BLOW_UP,  2*SPRITE_BLOW_UP
                DB  2*SPRITE_BLOW_UP, -1*SPRITE_BLOW_UP
                DB -1*SPRITE_BLOW_UP, -2*SPRITE_BLOW_UP
                DB  2*SPRITE_BLOW_UP, -2*SPRITE_BLOW_UP

vData = VectorList
VectorList:; moon knight
 DB $01, +$6E, +$07 ; sync and move to y, x
 DB $FF, -$03, +$08 ; draw, y, x
 DB $FF, -$04, +$03 ; draw, y, x
 DB $FF, -$0D, +$01 ; draw, y, x
 DB $FF, -$06, +$04 ; draw, y, x
 DB $FF, -$22, +$03 ; draw, y, x
 DB $FF, -$0F, +$09 ; draw, y, x
 DB $FF, -$05, +$04 ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, -$03, +$03 ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, -$0C, +$0F ; draw, y, x
 DB $FF, +$00, +$06 ; draw, y, x
 DB $FF, -$0A, +$18 ; draw, y, x
 DB $FF, +$00, +$04 ; draw, y, x
 DB $FF, -$04, +$01 ; draw, y, x
 DB $FF, -$2C, +$00 ; draw, y, x
 DB $FF, -$0F, -$0D ; draw, y, x
 DB $01, -$3E, +$52 ; sync and move to y, x
 DB $FF, -$0D, -$05 ; draw, y, x
 DB $FF, -$1D, -$54 ; draw, y, x
 DB $FF, -$09, -$09 ; draw, y, x
 DB $FF, +$01, -$4E ; draw, y, x
 DB $FF, +$7D, -$01 ; draw, y, x
 DB $FF, +$03, +$03 ; draw, y, x
 DB $FF, +$00, +$05 ; draw, y, x
 DB $FF, +$08, +$0C ; draw, y, x
 DB $FF, +$11, +$07 ; draw, y, x
 DB $FF, +$05, +$05 ; draw, y, x
 DB $FF, +$39, +$09 ; draw, y, x
 DB $FF, +$05, +$04 ; draw, y, x
 DB $FF, +$04, +$0A ; draw, y, x
 DB $FF, +$00, +$05 ; draw, y, x
 DB $FF, +$02, +$04 ; draw, y, x
 DB $FF, -$01, +$1E ; draw, y, x
 DB $FF, -$03, +$08 ; draw, y, x
 DB $01, +$55, -$29 ; sync and move to y, x
 DB $FF, -$1F, -$04 ; draw, y, x
 DB $FF, -$19, +$02 ; draw, y, x
 DB $FF, -$19, -$14 ; draw, y, x
 DB $FF, -$04, -$01 ; draw, y, x
 DB $FF, +$00, +$06 ; draw, y, x
 DB $FF, -$03, +$04 ; draw, y, x
 DB $FF, -$02, +$08 ; draw, y, x
 DB $FF, +$04, -$03 ; draw, y, x
 DB $FF, +$03, -$09 ; draw, y, x
 DB $FF, +$04, +$04 ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, -$05, +$0A ; draw, y, x
 DB $FF, -$02, +$02 ; draw, y, x
 DB $01, -$01, -$27 ; sync and move to y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, -$02, +$04 ; draw, y, x
 DB $FF, +$0D, -$11 ; draw, y, x
 DB $FF, +$03, +$03 ; draw, y, x
 DB $FF, -$0F, +$12 ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, -$02, -$02 ; draw, y, x
 DB $FF, -$01, -$02 ; draw, y, x
 DB $FF, +$01, -$14 ; draw, y, x
 DB $FF, +$05, -$06 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, +$01, -$02 ; draw, y, x
 DB $FF, -$01, +$02 ; draw, y, x
 DB $01, -$04, -$3D ; sync and move to y, x
 DB $FF, +$05, -$05 ; draw, y, x
 DB $FF, +$0A, -$01 ; draw, y, x
 DB $FF, +$08, -$03 ; draw, y, x
 DB $FF, +$00, -$03 ; draw, y, x
 DB $FF, -$07, -$03 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$00, -$03 ; draw, y, x
 DB $FF, -$05, +$0A ; draw, y, x
 DB $FF, +$03, -$14 ; draw, y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, -$0E, +$27 ; draw, y, x
 DB $FF, -$02, -$02 ; draw, y, x
 DB $01, -$0D, -$33 ; sync and move to y, x
 DB $FF, +$06, -$26 ; draw, y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, -$05, +$2D ; draw, y, x
 DB $FF, -$02, -$05 ; draw, y, x
 DB $FF, -$01, +$02 ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, +$03, -$1D ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, +$01, -$0B ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, -$05, +$2C ; draw, y, x
 DB $FF, +$01, +$02 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $01, -$1A, -$2C ; sync and move to y, x
 DB $FF, -$01, -$06 ; draw, y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, -$06, -$12 ; draw, y, x
 DB $FF, -$03, -$0A ; draw, y, x
 DB $FF, -$01, +$08 ; draw, y, x
 DB $FF, +$05, +$0D ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, -$0A, -$23 ; draw, y, x
 DB $FF, -$04, +$03 ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, -$36, -$01 ; draw, y, x
 DB $FF, -$02, +$49 ; draw, y, x
 DB $01, -$6F, -$13 ; sync and move to y, x
 DB $FF, +$08, +$08 ; draw, y, x
 DB $FF, +$19, +$47 ; draw, y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, +$03, +$01 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, +$17, +$0F ; draw, y, x
 DB $FF, -$01, -$02 ; draw, y, x
 DB $FF, +$04, -$19 ; draw, y, x
 DB $FF, +$02, -$05 ; draw, y, x
 DB $FF, -$01, -$05 ; draw, y, x
 DB $FF, +$04, -$04 ; draw, y, x
 DB $FF, +$01, -$04 ; draw, y, x
 DB $01, -$29, +$2B ; sync and move to y, x
 DB $FF, +$02, -$02 ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, -$02, +$04 ; draw, y, x
 DB $FF, -$03, +$03 ; draw, y, x
 DB $FF, -$0B, +$1E ; draw, y, x
 DB $FF, -$03, +$03 ; draw, y, x
 DB $FF, -$03, -$06 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, -$05, -$03 ; draw, y, x
 DB $FF, -$05, -$05 ; draw, y, x
 DB $FF, -$0B, -$23 ; draw, y, x
 DB $FF, +$08, -$1E ; draw, y, x
 DB $01, -$4F, -$07 ; sync and move to y, x
 DB $FF, +$05, +$04 ; draw, y, x
 DB $FF, +$04, +$04 ; draw, y, x
 DB $FF, +$00, +$07 ; draw, y, x
 DB $FF, -$05, +$0F ; draw, y, x
 DB $FF, +$01, +$0F ; draw, y, x
 DB $FF, +$02, +$04 ; draw, y, x
 DB $FF, -$01, +$02 ; draw, y, x
 DB $FF, +$03, +$03 ; draw, y, x
 DB $FF, +$09, -$0E ; draw, y, x
 DB $FF, -$01, +$07 ; draw, y, x
 DB $FF, -$05, +$10 ; draw, y, x
 DB $FF, +$04, +$05 ; draw, y, x
 DB $FF, +$05, -$18 ; draw, y, x
 DB $FF, +$14, -$1B ; draw, y, x
 DB $01, -$26, +$0A ; sync and move to y, x
 DB $FF, -$08, +$10 ; draw, y, x
 DB $FF, +$05, -$04 ; draw, y, x
 DB $FF, +$04, -$05 ; draw, y, x
 DB $FF, +$04, +$01 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, +$02, -$05 ; draw, y, x
 DB $FF, +$02, +$07 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, +$02, +$07 ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, +$02, +$02 ; draw, y, x
 DB $01, -$23, +$1F ; sync and move to y, x
 DB $FF, -$01, +$04 ; draw, y, x
 DB $FF, -$04, -$01 ; draw, y, x
 DB $FF, +$02, +$12 ; draw, y, x
 DB $FF, +$0C, -$26 ; draw, y, x
 DB $FF, +$04, -$05 ; draw, y, x
 DB $FF, +$04, +$04 ; draw, y, x
 DB $FF, +$0B, +$26 ; draw, y, x
 DB $FF, -$04, -$12 ; draw, y, x
 DB $FF, +$02, -$04 ; draw, y, x
 DB $FF, +$05, +$03 ; draw, y, x
 DB $FF, -$06, -$15 ; draw, y, x
 DB $FF, +$04, +$00 ; draw, y, x
 DB $FF, -$02, +$04 ; draw, y, x
 DB $FF, +$03, +$02 ; draw, y, x
 DB $01, -$05, +$11 ; sync and move to y, x
 DB $FF, -$02, +$02 ; draw, y, x
 DB $FF, +$04, +$09 ; draw, y, x
 DB $FF, +$01, +$0F ; draw, y, x
 DB $FF, -$07, -$0B ; draw, y, x
 DB $FF, -$01, +$03 ; draw, y, x
 DB $FF, +$07, +$09 ; draw, y, x
 DB $FF, +$00, +$08 ; draw, y, x
 DB $FF, +$04, -$11 ; draw, y, x
 DB $FF, -$04, -$1A ; draw, y, x
 DB $FF, -$08, -$0C ; draw, y, x
 DB $FF, -$0D, -$08 ; draw, y, x
 DB $FF, -$08, -$01 ; draw, y, x
 DB $FF, -$01, -$0B ; draw, y, x
 DB $01, -$21, -$17 ; sync and move to y, x
 DB $FF, +$00, +$0D ; draw, y, x
 DB $FF, -$08, +$0A ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, +$05, -$06 ; draw, y, x
 DB $FF, -$03, -$06 ; draw, y, x
 DB $FF, -$01, -$04 ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, +$01, -$02 ; draw, y, x
 DB $FF, -$03, -$04 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, -$01, +$03 ; draw, y, x
 DB $FF, +$0A, +$12 ; draw, y, x
 DB $FF, -$03, +$04 ; draw, y, x
 DB $FF, -$06, +$03 ; draw, y, x
 DB $01, -$31, -$03 ; sync and move to y, x
 DB $FF, +$00, -$02 ; draw, y, x
 DB $FF, +$01, -$05 ; draw, y, x
 DB $FF, -$04, -$01 ; draw, y, x
 DB $FF, -$01, +$04 ; draw, y, x
 DB $FF, +$03, +$03 ; draw, y, x
 DB $FF, -$08, +$06 ; draw, y, x
 DB $FF, +$00, -$03 ; draw, y, x
 DB $FF, -$02, -$09 ; draw, y, x
 DB $FF, -$05, -$0A ; draw, y, x
 DB $FF, +$07, +$18 ; draw, y, x
 DB $FF, -$06, +$03 ; draw, y, x
 DB $FF, -$04, -$06 ; draw, y, x
 DB $FF, +$02, +$04 ; draw, y, x
 DB $01, -$42, +$05 ; sync and move to y, x
 DB $FF, -$02, -$04 ; draw, y, x
 DB $FF, -$02, -$04 ; draw, y, x
 DB $FF, -$03, -$04 ; draw, y, x
 DB $FF, +$02, -$04 ; draw, y, x
 DB $FF, -$03, +$00 ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, -$0F, -$04 ; draw, y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$01, -$0E ; draw, y, x
 DB $FF, +$03, -$03 ; draw, y, x
 DB $FF, +$07, -$04 ; draw, y, x
 DB $FF, +$04, +$03 ; draw, y, x
 DB $01, -$55, -$29 ; sync and move to y, x
 DB $FF, +$21, +$02 ; draw, y, x
 DB $FF, +$11, +$0A ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$05, +$00 ; draw, y, x
 DB $FF, +$0D, +$04 ; draw, y, x
 DB $FF, +$0A, +$07 ; draw, y, x
 DB $FF, +$0A, +$0B ; draw, y, x
 DB $FF, +$07, +$11 ; draw, y, x
 DB $FF, +$05, +$05 ; draw, y, x
 DB $FF, +$02, +$04 ; draw, y, x
 DB $FF, -$02, +$04 ; draw, y, x
 DB $FF, -$01, -$02 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $01, +$0A, +$0F ; sync and move to y, x
 DB $FF, +$00, +$0B ; draw, y, x
 DB $FF, +$14, -$0C ; draw, y, x
 DB $FF, +$1F, +$00 ; draw, y, x
 DB $FF, -$07, -$0B ; draw, y, x
 DB $FF, +$00, -$07 ; draw, y, x
 DB $FF, +$09, +$11 ; draw, y, x
 DB $FF, +$0D, -$01 ; draw, y, x
 DB $FF, +$05, -$02 ; draw, y, x
 DB $FF, -$0E, -$13 ; draw, y, x
 DB $FF, -$06, -$03 ; draw, y, x
 DB $FF, +$01, -$04 ; draw, y, x
 DB $FF, +$0D, -$0A ; draw, y, x
 DB $FF, +$07, -$0E ; draw, y, x
 DB $FF, +$05, -$01 ; draw, y, x
 DB $01, +$39, -$20 ; sync and move to y, x
 DB $FF, -$04, +$0B ; draw, y, x
 DB $FF, +$01, -$0E ; draw, y, x
 DB $FF, +$08, -$0A ; draw, y, x
 DB $FF, -$05, +$0D ; draw, y, x
 DB $01, -$0B, +$1E ; sync and move to y, x
 DB $FF, -$03, -$04 ; draw, y, x
 DB $FF, +$00, -$04 ; draw, y, x
 DB $FF, -$01, -$08 ; draw, y, x
 DB $FF, -$02, -$05 ; draw, y, x
 DB $FF, +$01, -$02 ; draw, y, x
 DB $FF, +$01, +$04 ; draw, y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, +$03, +$0E ; draw, y, x
 DB $01, -$13, +$04 ; sync and move to y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, +$01, -$08 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, -$01, +$07 ; draw, y, x
 DB $01, -$1D, +$00 ; sync and move to y, x
 DB $FF, -$03, +$02 ; draw, y, x
 DB $FF, +$02, -$02 ; draw, y, x
 DB $FF, +$01, -$03 ; draw, y, x
 DB $01, -$32, +$11 ; sync and move to y, x
 DB $FF, -$11, +$11 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, -$01, -$04 ; draw, y, x
 DB $FF, +$16, -$17 ; draw, y, x
 DB $FF, -$02, +$06 ; draw, y, x
 DB $01, -$33, +$05 ; sync and move to y, x
 DB $FF, +$01, -$03 ; draw, y, x
 DB $FF, -$01, +$03 ; draw, y, x
 DB $01, -$56, -$07 ; sync and move to y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, +$09, +$00 ; draw, y, x
 DB $FF, -$04, +$01 ; draw, y, x
 DB $01, -$63, -$2A ; sync and move to y, x
 DB $FF, +$04, -$03 ; draw, y, x
 DB $FF, +$03, +$00 ; draw, y, x
 DB $FF, -$03, +$02 ; draw, y, x
 DB $FF, -$04, +$02 ; draw, y, x
 DB $01, -$61, -$30 ; sync and move to y, x
 DB $FF, -$07, +$02 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, +$08, -$01 ; draw, y, x
 DB $FF, -$03, +$02 ; draw, y, x
 DB $01, -$62, -$36 ; sync and move to y, x
 DB $FF, -$06, -$07 ; draw, y, x
 DB $FF, -$01, -$12 ; draw, y, x
 DB $FF, -$03, -$03 ; draw, y, x
 DB $FF, +$00, -$05 ; draw, y, x
 DB $FF, +$02, -$02 ; draw, y, x
 DB $FF, +$09, +$23 ; draw, y, x
 DB $01, +$26, +$19 ; sync and move to y, x
 DB $FF, -$12, +$03 ; draw, y, x
 DB $FF, +$11, -$01 ; draw, y, x
 DB $FF, +$03, -$03 ; draw, y, x
 DB $01, +$22, -$3F ; sync and move to y, x
 DB $FF, -$04, -$02 ; draw, y, x
 DB $FF, -$0E, +$01 ; draw, y, x
 DB $FF, +$15, +$03 ; draw, y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $01, +$09, +$27 ; sync and move to y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, +$02, +$06 ; draw, y, x
 DB $FF, -$01, -$09 ; draw, y, x
 DB $01, +$06, +$34 ; sync and move to y, x
 DB $FF, -$02, -$04 ; draw, y, x
 DB $FF, +$00, +$04 ; draw, y, x
 DB $FF, +$04, +$08 ; draw, y, x
 DB $FF, +$00, -$04 ; draw, y, x
 DB $FF, -$02, -$04 ; draw, y, x
 DB $01, +$02, +$35 ; sync and move to y, x
 DB $FF, -$01, -$02 ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, +$01, +$02 ; draw, y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, -$02, -$06 ; draw, y, x
 DB $01, -$0F, +$4E ; sync and move to y, x
 DB $FF, -$0C, -$29 ; draw, y, x
 DB $FF, -$02, +$02 ; draw, y, x
 DB $FF, +$0C, +$32 ; draw, y, x
 DB $FF, +$01, +$04 ; draw, y, x
 DB $FF, +$05, +$00 ; draw, y, x
 DB $FF, -$04, -$0F ; draw, y, x
 DB $01, -$1C, +$5A ; sync and move to y, x
 DB $FF, -$01, -$13 ; draw, y, x
 DB $FF, -$02, +$05 ; draw, y, x
 DB $FF, +$02, +$11 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $01, -$1F, -$55 ; sync and move to y, x
 DB $FF, +$00, -$06 ; draw, y, x
 DB $FF, -$02, +$0F ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, -$01, -$09 ; draw, y, x
 DB $01, -$23, -$4F ; sync and move to y, x
 DB $FF, -$03, -$0C ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $FF, +$07, +$11 ; draw, y, x
 DB $FF, +$00, -$05 ; draw, y, x
 DB $01, -$26, +$56 ; sync and move to y, x
 DB $FF, -$02, -$12 ; draw, y, x
 DB $FF, -$04, +$17 ; draw, y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$04, +$06 ; draw, y, x
 DB $FF, +$08, +$00 ; draw, y, x
 DB $FF, +$00, -$06 ; draw, y, x
 DB $01, -$35, -$24 ; sync and move to y, x
 DB $FF, -$08, -$02 ; draw, y, x
 DB $FF, +$04, +$03 ; draw, y, x
 DB $FF, +$05, +$01 ; draw, y, x
 DB $01, -$37, -$12 ; sync and move to y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$00, -$04 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, +$00, +$08 ; draw, y, x
 DB $FF, +$04, +$07 ; draw, y, x
 DB $FF, -$01, -$05 ; draw, y, x
 DB $01, -$3B, -$1F ; sync and move to y, x
 DB $FF, -$06, -$01 ; draw, y, x
 DB $FF, -$05, +$00 ; draw, y, x
 DB $FF, +$0B, +$03 ; draw, y, x
 DB $02 ; endmarker 

vData2 = VectorList2
BLOW_UP EQU 1
; khonshu sitting - unused
VectorList2:
 DB $01, +$34*BLOW_UP, +$3A*BLOW_UP ; sync and move to y, x
 DB $FF, +$07*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$14*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$10*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $01, +$44*BLOW_UP, +$1D*BLOW_UP ; sync and move to y, x
 DB $FF, -$05*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$1A*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$0C*BLOW_UP ; draw, y, x
 DB $01, +$41*BLOW_UP, -$21*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, -$0F*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$1C*BLOW_UP, +$16*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$0B*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$1A*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $01, +$5B*BLOW_UP, +$2A*BLOW_UP ; sync and move to y, x
 DB $00, +$11*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$0D*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$5B*BLOW_UP, +$18*BLOW_UP ; sync and move to y, x
 DB $FF, -$05*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, +$45*BLOW_UP, -$22*BLOW_UP ; sync and move to y, x
 DB $FF, +$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $01, +$4A*BLOW_UP, -$01*BLOW_UP ; sync and move to y, x
 DB $FF, +$09*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$0C*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $01, +$3D*BLOW_UP, -$30*BLOW_UP ; sync and move to y, x
 DB $FF, +$07*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, +$0B*BLOW_UP ; draw, y, x
 DB $01, -$0D*BLOW_UP, +$28*BLOW_UP ; sync and move to y, x
 DB $FF, +$1E*BLOW_UP, +$0D*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$0B*BLOW_UP, +$12*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$5B*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$0E*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$2F*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$2F*BLOW_UP, +$25*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $01, -$21*BLOW_UP, -$02*BLOW_UP ; sync and move to y, x
 DB $FF, +$02*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$13*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$0A*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $01, -$30*BLOW_UP, +$19*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$23*BLOW_UP, -$1A*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, +$0A*BLOW_UP, -$02*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$0C*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$0D*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$0D*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$06*BLOW_UP, +$15*BLOW_UP ; sync and move to y, x
 DB $FF, -$08*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$10*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$28*BLOW_UP, +$2C*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$22*BLOW_UP, +$3D*BLOW_UP ; sync and move to y, x
 DB $FF, +$05*BLOW_UP, +$0C*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$11*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$4C*BLOW_UP, -$0E*BLOW_UP ; draw, y, x
 DB $FF, +$0A*BLOW_UP, -$18*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $01, +$26*BLOW_UP, +$38*BLOW_UP ; sync and move to y, x
 DB $FF, -$10*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$0D*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, +$22*BLOW_UP, +$05*BLOW_UP ; sync and move to y, x
 DB $FF, -$0E*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$1F*BLOW_UP, +$2C*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$1F*BLOW_UP, +$29*BLOW_UP ; sync and move to y, x
 DB $FF, -$09*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $01, +$0F*BLOW_UP, +$2B*BLOW_UP ; sync and move to y, x
 DB $FF, -$0A*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$01*BLOW_UP, +$19*BLOW_UP ; sync and move to y, x
 DB $FF, +$15*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, +$14*BLOW_UP, +$29*BLOW_UP ; sync and move to y, x
 DB $FF, -$0A*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $01, +$12*BLOW_UP, +$38*BLOW_UP ; sync and move to y, x
 DB $FF, -$23*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, +$0B*BLOW_UP, +$4A*BLOW_UP ; sync and move to y, x
 DB $FF, -$2B*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$0E*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $01, -$03*BLOW_UP, +$1B*BLOW_UP ; sync and move to y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, -$42*BLOW_UP, +$15*BLOW_UP ; sync and move to y, x
 DB $FF, -$22*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, -$0B*BLOW_UP ; draw, y, x
 DB $FF, +$16*BLOW_UP, -$0B*BLOW_UP ; draw, y, x
 DB $FF, +$12*BLOW_UP, -$13*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$2A*BLOW_UP, -$1B*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$11*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, -$0D*BLOW_UP ; draw, y, x
 DB $FF, +$22*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, -$5B*BLOW_UP ; sync and move to y, x
 DB $00, +$00*BLOW_UP, -$03*BLOW_UP ; additional sync move to y, x
 DB $FF, -$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$0C*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $FF, +$17*BLOW_UP, +$15*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $01, -$3B*BLOW_UP, +$43*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $01, -$5B*BLOW_UP, +$07*BLOW_UP ; sync and move to y, x
 DB $00, -$10*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $02 ; endmarker

vData3 = VectorList3
; khonshu revival
VectorList3:
 DB $01, +$4B*BLOW_UP, -$05*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$63*BLOW_UP, +$01*BLOW_UP ; sync and move to y, x
 DB $00, +$09*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, +$0D*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $01, +$63*BLOW_UP, +$0F*BLOW_UP ; sync and move to y, x
 DB $00, +$06*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$07*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $01, +$52*BLOW_UP, +$27*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$0C*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$52*BLOW_UP, +$27*BLOW_UP ; sync and move to y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$63*BLOW_UP, -$05*BLOW_UP ; sync and move to y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$0C*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, +$61*BLOW_UP, +$0F*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $01, +$55*BLOW_UP, +$04*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $01, +$4B*BLOW_UP, +$18*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $01, +$41*BLOW_UP, +$19*BLOW_UP ; sync and move to y, x
 DB $FF, -$08*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $01, +$39*BLOW_UP, +$26*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$12*BLOW_UP, -$15*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $01, +$0B*BLOW_UP, +$05*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$3C*BLOW_UP, +$16*BLOW_UP ; sync and move to y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, +$3C*BLOW_UP, +$1D*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, -$10*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $01, +$37*BLOW_UP, +$2D*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, +$2F*BLOW_UP, +$55*BLOW_UP ; sync and move to y, x
 DB $FF, +$02*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$1A*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $FF, -$63*BLOW_UP, +$10*BLOW_UP ; draw, y, x
 DB $01, +$39*BLOW_UP, +$27*BLOW_UP ; sync and move to y, x
 DB $FF, -$06*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $01, +$2F*BLOW_UP, -$0A*BLOW_UP ; sync and move to y, x
 DB $FF, -$04*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$2F*BLOW_UP, -$0A*BLOW_UP ; sync and move to y, x
 DB $FF, +$06*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $01, +$30*BLOW_UP, -$0A*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, -$63*BLOW_UP, -$46*BLOW_UP ; sync and move to y, x
 DB $00, -$0B*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, +$4D*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$18*BLOW_UP, -$18*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$0E*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$0C*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $01, +$2C*BLOW_UP, -$5F*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $01, +$28*BLOW_UP, +$17*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, +$22*BLOW_UP, -$02*BLOW_UP ; sync and move to y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$17*BLOW_UP ; draw, y, x
 DB $01, +$27*BLOW_UP, +$17*BLOW_UP ; sync and move to y, x
 DB $FF, -$12*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$2F*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$10*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$21*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, +$22*BLOW_UP, -$02*BLOW_UP ; sync and move to y, x
 DB $FF, -$05*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, +$21*BLOW_UP, -$03*BLOW_UP ; sync and move to y, x
 DB $FF, -$0F*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$11*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$10*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$0A*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$0A*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$15*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $02 ; endmarker

vData4 = VectorList4
; fancy rabbit
VectorList4:
 DB $01, +$29*BLOW_UP, +$29*BLOW_UP ; sync and move to y, x
 DB $00, +$29*BLOW_UP, +$03*BLOW_UP ; additional sync move to y, x
 DB $00, +$14*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$0F*BLOW_UP ; draw, y, x
 DB $FF, -$27*BLOW_UP, -$0D*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$0D*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$14*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, -$13*BLOW_UP ; draw, y, x
 DB $FF, -$16*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$16*BLOW_UP ; draw, y, x
 DB $FF, -$09*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, +$29*BLOW_UP, -$16*BLOW_UP ; sync and move to y, x
 DB $00, +$10*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$16*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$15*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$11*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$1A*BLOW_UP, -$1A*BLOW_UP ; draw, y, x
 DB $FF, -$17*BLOW_UP, -$0D*BLOW_UP ; draw, y, x
 DB $FF, -$18*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$17*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$15*BLOW_UP, +$0B*BLOW_UP ; draw, y, x
 DB $FF, +$17*BLOW_UP, +$19*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$08*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, -$25*BLOW_UP, -$1B*BLOW_UP ; sync and move to y, x
 DB $FF, -$05*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$1A*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$13*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$15*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$1F*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$0D*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $FF, +$10*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$11*BLOW_UP, +$12*BLOW_UP ; draw, y, x
 DB $FF, -$10*BLOW_UP, +$0C*BLOW_UP ; draw, y, x
 DB $FF, -$1A*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, +$29*BLOW_UP ; sync and move to y, x
 DB $00, -$22*BLOW_UP, +$0E*BLOW_UP ; additional sync move to y, x
 DB $FF, -$15*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$16*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$1A*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, -$0D*BLOW_UP ; draw, y, x
 DB $FF, +$10*BLOW_UP, -$11*BLOW_UP ; draw, y, x
 DB $FF, +$0A*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$0D*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$0E*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$0A*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$21*BLOW_UP, +$10*BLOW_UP ; draw, y, x
 DB $FF, +$0B*BLOW_UP, +$19*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, +$0B*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, -$10*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $01, +$29*BLOW_UP, +$29*BLOW_UP ; sync and move to y, x
 DB $00, +$29*BLOW_UP, +$16*BLOW_UP ; additional sync move to y, x
 DB $00, +$0F*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$04*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$18*BLOW_UP ; draw, y, x
 DB $FF, -$22*BLOW_UP, -$11*BLOW_UP ; draw, y, x
 DB $FF, -$0C*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$0C*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$0D*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, -$0C*BLOW_UP, -$11*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, -$11*BLOW_UP ; draw, y, x
 DB $FF, +$0F*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$14*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$16*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $01, +$29*BLOW_UP, -$19*BLOW_UP ; sync and move to y, x
 DB $00, +$06*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, +$07*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$12*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$16*BLOW_UP ; draw, y, x
 DB $FF, +$11*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$0B*BLOW_UP ; draw, y, x
 DB $FF, -$14*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $FF, -$12*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$0E*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$0B*BLOW_UP ; draw, y, x
 DB $FF, +$29*BLOW_UP, +$0D*BLOW_UP ; draw, y, x
 DB $FF, +$0B*BLOW_UP, +$0F*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$08*BLOW_UP ; draw, y, x
 DB $01, -$10*BLOW_UP, +$0F*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$0A*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$15*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$07*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, +$10*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$0D*BLOW_UP, +$11*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $01, -$10*BLOW_UP, -$12*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$0A*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, -$10*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, -$09*BLOW_UP ; draw, y, x
 DB $FF, +$09*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$0D*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $01, -$15*BLOW_UP, -$03*BLOW_UP ; sync and move to y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $01, -$22*BLOW_UP, +$02*BLOW_UP ; sync and move to y, x
 DB $FF, -$06*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, +$02*BLOW_UP ; sync and move to y, x
 DB $00, -$05*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$0D*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, -$03*BLOW_UP ; sync and move to y, x
 DB $00, -$17*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$0C*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$09*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $01, +$1F*BLOW_UP, +$03*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$05*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$09*BLOW_UP, +$08*BLOW_UP ; sync and move to y, x
 DB $FF, +$00*BLOW_UP, +$04*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$05*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$05*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$17*BLOW_UP, +$0C*BLOW_UP ; sync and move to y, x
 DB $FF, -$04*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, -$04*BLOW_UP ; draw, y, x
 DB $FF, +$08*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, +$20*BLOW_UP, -$0F*BLOW_UP ; sync and move to y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$06*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$1A*BLOW_UP, -$0B*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$07*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $01, +$08*BLOW_UP, -$19*BLOW_UP ; sync and move to y, x
 DB $FF, -$03*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$06*BLOW_UP, -$06*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$01*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, -$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $01, +$01*BLOW_UP, -$0D*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$06*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, +$07*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $01, +$02*BLOW_UP, +$11*BLOW_UP ; sync and move to y, x
 DB $FF, +$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, +$01*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, +$03*BLOW_UP, -$04*BLOW_UP ; sync and move to y, x
 DB $FF, -$02*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$01*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$02*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$02*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$00*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $FF, +$03*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$04*BLOW_UP, +$00*BLOW_UP ; draw, y, x
 DB $FF, -$04*BLOW_UP, -$02*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, -$29*BLOW_UP ; sync and move to y, x
 DB $00, -$1C*BLOW_UP, -$01*BLOW_UP ; additional sync move to y, x
 DB $FF, -$0C*BLOW_UP, -$07*BLOW_UP ; draw, y, x
 DB $FF, -$13*BLOW_UP, -$03*BLOW_UP ; draw, y, x
 DB $FF, +$12*BLOW_UP, +$05*BLOW_UP ; draw, y, x
 DB $FF, +$18*BLOW_UP, +$0D*BLOW_UP ; draw, y, x
 DB $FF, -$0B*BLOW_UP, -$08*BLOW_UP ; draw, y, x
 DB $01, -$29*BLOW_UP, +$1D*BLOW_UP ; sync and move to y, x
 DB $00, -$14*BLOW_UP, +$00*BLOW_UP ; additional sync move to y, x
 DB $FF, -$1C*BLOW_UP, +$0A*BLOW_UP ; draw, y, x
 DB $FF, -$0F*BLOW_UP, +$02*BLOW_UP ; draw, y, x
 DB $FF, +$10*BLOW_UP, -$01*BLOW_UP ; draw, y, x
 DB $FF, +$1C*BLOW_UP, -$0A*BLOW_UP ; draw, y, x
 DB $02 ; endmarker

vData5 = VectorList5

VectorList5:
 DB $01, +$0A, -$07 ; sync and move to y, x
 DB $00, +$01, +$00 ; additional sync move to y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, +$01, +$05 ; draw, y, x
 DB $FF, -$01, +$02 ; draw, y, x
 DB $FF, +$04, +$06 ; draw, y, x
 DB $FF, -$04, +$02 ; draw, y, x
 DB $FF, -$06, -$02 ; draw, y, x
 DB $FF, -$08, +$03 ; draw, y, x
 DB $FF, -$01, -$06 ; draw, y, x
 DB $FF, -$05, -$03 ; draw, y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$01, -$02 ; draw, y, x
 DB $FF, +$05, -$04 ; draw, y, x
 DB $FF, +$01, -$02 ; draw, y, x
 DB $FF, +$01, -$04 ; draw, y, x
 DB $FF, +$07, +$02 ; draw, y, x
 DB $FF, +$07, -$01 ; draw, y, x
 DB $FF, +$04, +$02 ; draw, y, x
 DB $FF, -$02, +$02 ; draw, y, x
 DB $01, +$0A, -$09 ; sync and move to y, x
 DB $00, +$02, +$00 ; additional sync move to y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $FF, -$06, +$02 ; draw, y, x
 DB $FF, +$03, +$01 ; draw, y, x
 DB $FF, -$0A, -$04 ; draw, y, x
 DB $FF, -$02, +$06 ; draw, y, x
 DB $FF, -$05, +$02 ; draw, y, x
 DB $FF, -$02, +$04 ; draw, y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, +$05, +$02 ; draw, y, x
 DB $FF, +$02, +$06 ; draw, y, x
 DB $FF, +$0A, -$04 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, +$05, +$02 ; draw, y, x
 DB $FF, +$04, -$02 ; draw, y, x
 DB $FF, -$03, -$04 ; draw, y, x
 DB $FF, +$01, -$04 ; draw, y, x
 DB $FF, -$01, -$05 ; draw, y, x
 DB $FF, +$03, -$04 ; draw, y, x
 DB $02 ; endmarker 

marcFaceU:
 DB $01, +$0D, +$03 ; sync and move to y, x
 DB $FF, -$01, +$03 ; draw, y, x
 DB $FF, -$14, +$08 ; draw, y, x
 DB $FF, -$01, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$05, -$0D ; draw, y, x
 DB $FF, +$00, -$02 ; draw, y, x
 DB $FF, +$05, -$0E ; draw, y, x
 DB $FF, +$01, +$00 ; draw, y, x
 DB $FF, +$01, +$01 ; draw, y, x
 DB $FF, +$13, +$07 ; draw, y, x
 DB $FF, +$03, +$07 ; draw, y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $01, +$0D, -$03 ; sync and move to y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $FF, -$15, -$08 ; draw, y, x
 DB $FF, -$04, +$0C ; draw, y, x
 DB $FF, +$00, +$03 ; draw, y, x
 DB $FF, +$04, +$0D ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$15, -$08 ; draw, y, x
 DB $FF, +$02, -$06 ; draw, y, x
 DB $FF, -$01, -$03 ; draw, y, x
 DB $01, +$07, +$06 ; sync and move to y, x
 DB $FF, -$0D, +$05 ; draw, y, x
 DB $FF, -$07, -$0B ; draw, y, x
 DB $FF, +$07, +$0A ; draw, y, x
 DB $FF, +$0C, -$04 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$02, -$06 ; draw, y, x
 DB $FF, +$02, -$05 ; draw, y, x
 DB $FF, +$00, -$01 ; draw, y, x
 DB $FF, -$0C, -$04 ; draw, y, x
 DB $FF, -$07, +$09 ; draw, y, x
 DB $FF, +$07, -$09 ; draw, y, x
 DB $FF, +$0D, +$04 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$03, +$06 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $02 ; endmarker 

marcFaceR:
 DB $01, -$03, +$0D ; sync and move to y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $FF, -$08, -$14 ; draw, y, x
 DB $FF, +$00, -$01 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$0D, -$05 ; draw, y, x
 DB $FF, +$02, +$00 ; draw, y, x
 DB $FF, +$0E, +$05 ; draw, y, x
 DB $FF, +$00, +$01 ; draw, y, x
 DB $FF, -$01, +$01 ; draw, y, x
 DB $FF, -$07, +$13 ; draw, y, x
 DB $FF, -$07, +$03 ; draw, y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $01, +$03, +$0D ; sync and move to y, x
 DB $FF, +$03, -$01 ; draw, y, x
 DB $FF, +$08, -$15 ; draw, y, x
 DB $FF, -$0C, -$04 ; draw, y, x
 DB $FF, -$03, +$00 ; draw, y, x
 DB $FF, -$0D, +$04 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$08, +$15 ; draw, y, x
 DB $FF, +$06, +$02 ; draw, y, x
 DB $FF, +$03, -$01 ; draw, y, x
 DB $01, -$06, +$07 ; sync and move to y, x
 DB $FF, -$05, -$0D ; draw, y, x
 DB $FF, +$0B, -$07 ; draw, y, x
 DB $FF, -$0A, +$07 ; draw, y, x
 DB $FF, +$04, +$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$06, -$02 ; draw, y, x
 DB $FF, +$05, +$02 ; draw, y, x
 DB $FF, +$01, +$00 ; draw, y, x
 DB $FF, +$04, -$0C ; draw, y, x
 DB $FF, -$09, -$07 ; draw, y, x
 DB $FF, +$09, +$07 ; draw, y, x
 DB $FF, -$04, +$0D ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$06, -$03 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $02 ; endmarker 

marcFaceL:
 DB $01, +$03, -$0D ; sync and move to y, x
 DB $FF, +$03, +$01 ; draw, y, x
 DB $FF, +$08, +$14 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$0D, +$06 ; draw, y, x
 DB $FF, -$02, +$00 ; draw, y, x
 DB $FF, -$0E, -$05 ; draw, y, x
 DB $FF, +$00, -$01 ; draw, y, x
 DB $FF, +$01, -$01 ; draw, y, x
 DB $FF, +$08, -$13 ; draw, y, x
 DB $FF, +$06, -$04 ; draw, y, x
 DB $FF, +$03, +$03 ; draw, y, x
 DB $01, -$03, -$0D ; sync and move to y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $FF, -$08, +$14 ; draw, y, x
 DB $FF, +$0C, +$05 ; draw, y, x
 DB $FF, +$03, +$00 ; draw, y, x
 DB $FF, +$0D, -$05 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$08, -$14 ; draw, y, x
 DB $FF, -$06, -$02 ; draw, y, x
 DB $FF, -$03, +$01 ; draw, y, x
 DB $01, +$06, -$07 ; sync and move to y, x
 DB $FF, +$05, +$0D ; draw, y, x
 DB $FF, -$0B, +$07 ; draw, y, x
 DB $FF, +$0A, -$07 ; draw, y, x
 DB $FF, -$04, -$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$06, +$02 ; draw, y, x
 DB $FF, -$05, -$02 ; draw, y, x
 DB $FF, -$01, +$00 ; draw, y, x
 DB $FF, -$04, +$0C ; draw, y, x
 DB $FF, +$09, +$07 ; draw, y, x
 DB $FF, -$09, -$07 ; draw, y, x
 DB $FF, +$04, -$0D ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$06, +$03 ; draw, y, x
 DB $FF, +$04, -$01 ; draw, y, x
 DB $02 ; endmarker 

marcFaceD:
 DB $01, -$0D, -$03 ; sync and move to y, x
 DB $FF, +$01, -$03 ; draw, y, x
 DB $FF, +$14, -$08 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$06, +$0D ; draw, y, x
 DB $FF, +$00, +$02 ; draw, y, x
 DB $FF, -$05, +$0E ; draw, y, x
 DB $FF, -$01, +$00 ; draw, y, x
 DB $FF, -$01, -$01 ; draw, y, x
 DB $FF, -$13, -$08 ; draw, y, x
 DB $FF, -$04, -$06 ; draw, y, x
 DB $FF, +$03, -$03 ; draw, y, x
 DB $01, -$0D, +$03 ; sync and move to y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $FF, +$14, +$08 ; draw, y, x
 DB $FF, +$05, -$0C ; draw, y, x
 DB $FF, +$00, -$03 ; draw, y, x
 DB $FF, -$05, -$0D ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$14, +$08 ; draw, y, x
 DB $FF, -$02, +$06 ; draw, y, x
 DB $FF, +$01, +$03 ; draw, y, x
 DB $01, -$07, -$06 ; sync and move to y, x
 DB $FF, +$0D, -$05 ; draw, y, x
 DB $FF, +$07, +$0B ; draw, y, x
 DB $FF, -$07, -$0A ; draw, y, x
 DB $FF, -$0C, +$04 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$02, +$06 ; draw, y, x
 DB $FF, -$02, +$05 ; draw, y, x
 DB $FF, +$00, +$01 ; draw, y, x
 DB $FF, +$0C, +$04 ; draw, y, x
 DB $FF, +$07, -$09 ; draw, y, x
 DB $FF, -$07, +$09 ; draw, y, x
 DB $FF, -$0D, -$04 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$03, -$06 ; draw, y, x
 DB $FF, -$01, -$04 ; draw, y, x
 DB $02 ; endmarker 

marcFaceUL:
 DB $01, +$0B, -$07 ; sync and move to y, x
 DB $FF, +$02, +$03 ; draw, y, x
 DB $FF, -$09, +$14 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$0D, -$05 ; draw, y, x
 DB $FF, -$02, -$02 ; draw, y, x
 DB $FF, -$06, -$0D ; draw, y, x
 DB $FF, +$01, -$01 ; draw, y, x
 DB $FF, +$01, +$00 ; draw, y, x
 DB $FF, +$13, -$08 ; draw, y, x
 DB $FF, +$07, +$02 ; draw, y, x
 DB $FF, +$00, +$04 ; draw, y, x
 DB $01, +$07, -$0B ; sync and move to y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $FF, -$14, +$09 ; draw, y, x
 DB $FF, +$05, +$0C ; draw, y, x
 DB $FF, +$03, +$02 ; draw, y, x
 DB $FF, +$0C, +$06 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$09, -$14 ; draw, y, x
 DB $FF, -$03, -$06 ; draw, y, x
 DB $FF, -$03, -$01 ; draw, y, x
 DB $01, +$09, -$01 ; sync and move to y, x
 DB $FF, -$05, +$0D ; draw, y, x
 DB $FF, -$0D, -$03 ; draw, y, x
 DB $FF, +$0C, +$02 ; draw, y, x
 DB $FF, +$05, -$0B ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$05, -$03 ; draw, y, x
 DB $FF, -$02, -$05 ; draw, y, x
 DB $FF, -$01, +$00 ; draw, y, x
 DB $FF, -$0B, +$05 ; draw, y, x
 DB $FF, +$01, +$0B ; draw, y, x
 DB $FF, -$01, -$0B ; draw, y, x
 DB $FF, +$0C, -$06 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$02, +$06 ; draw, y, x
 DB $FF, +$03, +$02 ; draw, y, x
 DB $02 ; endmarker 

marcFaceDL:
 DB $01, -$07, -$0B ; sync and move to y, x
 DB $FF, +$03, -$02 ; draw, y, x
 DB $FF, +$14, +$09 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$05, +$0D ; draw, y, x
 DB $FF, -$02, +$02 ; draw, y, x
 DB $FF, -$0D, +$06 ; draw, y, x
 DB $FF, -$01, -$01 ; draw, y, x
 DB $FF, +$00, -$01 ; draw, y, x
 DB $FF, -$08, -$13 ; draw, y, x
 DB $FF, +$02, -$07 ; draw, y, x
 DB $FF, +$04, +$00 ; draw, y, x
 DB $01, -$0B, -$07 ; sync and move to y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, +$09, +$14 ; draw, y, x
 DB $FF, +$0C, -$05 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, +$06, -$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$14, -$09 ; draw, y, x
 DB $FF, -$06, +$03 ; draw, y, x
 DB $FF, -$01, +$03 ; draw, y, x
 DB $01, -$01, -$09 ; sync and move to y, x
 DB $FF, +$0D, +$05 ; draw, y, x
 DB $FF, -$03, +$0D ; draw, y, x
 DB $FF, +$02, -$0C ; draw, y, x
 DB $FF, -$0B, -$05 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$03, +$05 ; draw, y, x
 DB $FF, -$05, +$02 ; draw, y, x
 DB $FF, +$00, +$01 ; draw, y, x
 DB $FF, +$05, +$0B ; draw, y, x
 DB $FF, +$0B, -$01 ; draw, y, x
 DB $FF, -$0B, +$01 ; draw, y, x
 DB $FF, -$06, -$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$06, -$02 ; draw, y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $02 ; endmarker 

marcFaceDR:
 DB $01, -$0B, +$07 ; sync and move to y, x
 DB $FF, -$02, -$03 ; draw, y, x
 DB $FF, +$09, -$14 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$0D, +$05 ; draw, y, x
 DB $FF, +$02, +$02 ; draw, y, x
 DB $FF, +$06, +$0D ; draw, y, x
 DB $FF, -$01, +$01 ; draw, y, x
 DB $FF, -$01, +$00 ; draw, y, x
 DB $FF, -$13, +$08 ; draw, y, x
 DB $FF, -$07, -$02 ; draw, y, x
 DB $FF, +$00, -$04 ; draw, y, x
 DB $01, -$07, +$0B ; sync and move to y, x
 DB $FF, +$03, +$02 ; draw, y, x
 DB $FF, +$14, -$09 ; draw, y, x
 DB $FF, -$05, -$0C ; draw, y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $FF, -$0C, -$06 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$09, +$14 ; draw, y, x
 DB $FF, +$03, +$06 ; draw, y, x
 DB $FF, +$03, +$01 ; draw, y, x
 DB $01, -$09, +$01 ; sync and move to y, x
 DB $FF, +$05, -$0D ; draw, y, x
 DB $FF, +$0D, +$03 ; draw, y, x
 DB $FF, -$0C, -$02 ; draw, y, x
 DB $FF, -$05, +$0B ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$05, +$03 ; draw, y, x
 DB $FF, +$02, +$05 ; draw, y, x
 DB $FF, +$01, +$00 ; draw, y, x
 DB $FF, +$0B, -$05 ; draw, y, x
 DB $FF, -$01, -$0B ; draw, y, x
 DB $FF, +$01, +$0B ; draw, y, x
 DB $FF, -$0C, +$06 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$02, -$06 ; draw, y, x
 DB $FF, -$03, -$02 ; draw, y, x
 DB $02 ; endmarker 

marcFaceUR:
 DB $01, +$07, +$0B ; sync and move to y, x
 DB $FF, -$03, +$02 ; draw, y, x
 DB $FF, -$14, -$09 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$05, -$0D ; draw, y, x
 DB $FF, +$02, -$02 ; draw, y, x
 DB $FF, +$0D, -$06 ; draw, y, x
 DB $FF, +$01, +$01 ; draw, y, x
 DB $FF, +$00, +$01 ; draw, y, x
 DB $FF, +$08, +$13 ; draw, y, x
 DB $FF, -$02, +$07 ; draw, y, x
 DB $FF, -$04, +$00 ; draw, y, x
 DB $01, +$0B, +$07 ; sync and move to y, x
 DB $FF, +$02, -$03 ; draw, y, x
 DB $FF, -$09, -$14 ; draw, y, x
 DB $FF, -$0C, +$05 ; draw, y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $FF, -$06, +$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$14, +$09 ; draw, y, x
 DB $FF, +$06, -$03 ; draw, y, x
 DB $FF, +$01, -$03 ; draw, y, x
 DB $01, +$01, +$09 ; sync and move to y, x
 DB $FF, -$0D, -$05 ; draw, y, x
 DB $FF, +$03, -$0D ; draw, y, x
 DB $FF, -$02, +$0C ; draw, y, x
 DB $FF, +$0B, +$05 ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, +$03, -$05 ; draw, y, x
 DB $FF, +$05, -$02 ; draw, y, x
 DB $FF, +$00, -$01 ; draw, y, x
 DB $FF, -$05, -$0B ; draw, y, x
 DB $FF, -$0B, +$01 ; draw, y, x
 DB $FF, +$0B, -$01 ; draw, y, x
 DB $FF, +$06, +$0C ; draw, y, x
 DB $FF, +$00, +$00 ; draw, y, x
 DB $FF, -$06, +$02 ; draw, y, x
 DB $FF, -$02, +$03 ; draw, y, x
 DB $02 ; endmarker 

	END start