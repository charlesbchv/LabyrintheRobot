	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui m�me)



		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; d�activer le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri�re
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; d�activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri�re
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
			
		IMPORT	LED_INIT
		IMPORT	LED_GAUCHE_ON
		IMPORT  LED_GAUCHE_OFF
		IMPORT	LED_DROITE_ON
		IMPORT  LED_DROITE_OFF

SYSCTL_PERIPH_GPIO	EQU		0x400FE108

GPIO_PORTD_BASE		EQU		0x40007000
GPIO_PORTE_BASE     EQU     0x40024000
GPIO_PORTF_BASE     EQU     0x40025000

GPIO_O_DIR          EQU     0x00000400
GPIO_O_DR2R   		EQU 	0x00000500
GPIO_O_DEN			EQU		0x0000051C
GPIO_I_PUR			EQU		0x00000510

BROCHE0             EQU     0x01
BROCHE1             EQU     0x02
BROCHE0_1           EQU     0x03
BROCHE4_5           EQU     0x30
BROCHE6				EQU		0x40
BROCHE7				EQU		0x80
BROCHE6_7			EQU		0xC0

DUREE   			EQU     0x0002FFFF
DUREE2   			EQU     0x0000000F
DUREE3   			EQU     0x006FFFFF
DUREE4   			EQU     0x000000FF

__main	

		LDR R6, = SYSCTL_PERIPH_GPIO
		MOV R0, #0x00000038
		STR R0, [R6]

		NOP
		NOP
		NOP

; ###### CONFIG SWITCHES #################################
		LDR R7, = GPIO_PORTD_BASE+GPIO_I_PUR
		LDR R0, = BROCHE6_7
		STR R0, [R7]

		LDR R7, = GPIO_PORTD_BASE+GPIO_O_DEN
		LDR R0, = BROCHE6_7
		STR R0, [R7]

		LDR R1, = GPIO_PORTD_BASE + (BROCHE6<<2)
		LDR R2, = GPIO_PORTD_BASE + (BROCHE7<<2)
; ########################################################

; ###### CONFIG BUMPERS ##################################        
		LDR R7, = GPIO_PORTE_BASE+GPIO_I_PUR
		LDR R0, = BROCHE0_1
		STR R0, [R7]

		LDR R7, = GPIO_PORTE_BASE+GPIO_O_DEN
		LDR R0, = BROCHE0_1
		STR R0, [R7]

		LDR R3, = GPIO_PORTE_BASE + (BROCHE0<<2)
		LDR R4, = GPIO_PORTE_BASE + (BROCHE1<<2)
; ########################################################


		BL	MOTEUR_INIT
		BL	LED_INIT

IDLE
		LDR R10, [R1]
		CMP R10, #0x00
		BEQ SCENE_1

		LDR R10, [R2]
		CMP R10, #0x00
		BEQ SCENE_2
		
		B	IDLE
		
SCENE_1
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		B	DETECT_SCENE_1
		
DETECT_SCENE_1
		LDR R10, [R3]
		CMP R10, #0x00
		BEQ CRASHED_SCENE_1

		LDR R10, [R4]
		CMP R10, #0x00
		BEQ CRASHED_SCENE_1
		
		B	DETECT_SCENE_1
		
CRASHED_SCENE_1
		BL	MOTEUR_GAUCHE_ARRIERE
		BL	MOTEUR_DROIT_ARRIERE
        LDR R6, = DUREE2
		B	LOOP_SCENE_1
		
LOOP_SCENE_1
		SUBS R6, #1
		BEQ	END_SCENE_1
		
		BL	LED_GAUCHE_ON
		LDR R7, = DUREE
		B	LOOP_G_SCENE_1
		
LOOP_G_SCENE_1
		SUBS R7, #1
        BNE	LOOP_G_SCENE_1
		
		BL	LED_GAUCHE_OFF
		BL	LED_DROITE_ON
		LDR R7, = DUREE
		B	LOOP_D_SCENE_1
		
LOOP_D_SCENE_1
		SUBS R7, #1
        BNE	LOOP_D_SCENE_1
		
		BL	LED_GAUCHE_ON
		BL	LED_DROITE_OFF
		LDR R7, = DUREE
		B	LOOP_SCENE_1
		
END_SCENE_1
		BL	LED_DROITE_OFF
		BL	LED_GAUCHE_OFF
		BL	MOTEUR_GAUCHE_OFF
		BL	MOTEUR_DROIT_OFF
		B	IDLE
		
		

SCENE_2
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		BL	LED_GAUCHE_ON
		BL	LED_DROITE_ON
		B	DETECT_SCENE_2
		
DETECT_SCENE_2
		ADD	R8, #1

		LDR R10, [R3]
		CMP R10, #0x00
		BEQ HIT_SCENE_2

		LDR R10, [R4]
		CMP R10, #0x00
		BEQ HIT_SCENE_2

		LDR R10, [R1]
		CMP R10, #0x00
		BEQ STOP_SCENE_2
		
		B	DETECT_SCENE_2
		
HIT_SCENE_2
		MOV	R7, R8
		AND	R7, #1
		CMP	R7, #0
		BEQ	HIT_SCENE_2_1
		B	HIT_SCENE_2_2
	
HIT_SCENE_2_1
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL	LED_GAUCHE_OFF
		BL	LED_DROITE_OFF
		LDR R7, = DUREE3
		B	TURN_SCENE_2
		
HIT_SCENE_2_2
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_AVANT
		BL	LED_GAUCHE_OFF
		BL	LED_DROITE_OFF
		LDR R7, = DUREE3
		B	TURN_SCENE_2

TURN_SCENE_2
		SUBS R7, #1
        BNE	TURN_SCENE_2
		
		B	SCENE_2
		
STOP_SCENE_2
		BL	LED_DROITE_OFF
		BL	LED_GAUCHE_OFF
		BL	MOTEUR_GAUCHE_OFF
		BL	MOTEUR_DROIT_OFF
		LDR R7, = DUREE3
		B	STOP_LOOP_SCENE_2

STOP_LOOP_SCENE_2
		SUBS R7, #1
        BNE	STOP_LOOP_SCENE_2
		
		B	IDLE
		
		NOP
		NOP
		NOP
		END