;
; AssemblerApplication10.asm
;prelab 3
; Created: 8/02/2024 22:16:47
; Author : diego
;


; Replace with your application code
.include "M328PDEF.inc"
.cseg ;definir que se va  iniciatr el segmento de código del programa
.org 0x00;en que parte del código vamos a iniciar
	JMP MAIN
.org 0x0006 ;usar interruptor in-change
	JMP PCINT0 ;como lo configuro para que se ejecuta la interrupcion en el flanco positivo o negativo?
.org 0x0008
	JMP PCINT1 ;interrucpion para disminuir el contador
.org 0x001A
	JMP TIMER0_OVF ;interrupcion cuando hay un overflow en el timer0
MAIN:
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17

SETUP:
	//reduciendo la frecuencia a 2M de oscilaciones
	LDI R16, (1 << CLKPCE) ;colocar 1 en el 7mo bit del registro CLKPR
	STS CLKPR, R16 ;mover a CLKPR
	LDI R16, 0b0000_0011 ;dividir la frecuencia del clk en 8, 16M/8 = 2M oscilaciones por segundo
	STS CLKPR, R16 ;mover a CLKPR
	//definiendo salidas y entradas
	//botones portC
	SBI PORTC, PC4 ;habilitando pull up
	CBI DDRC, PC4 ;definiendo entrada
	SBI PORTC, PC5 ;habilitando pull up
	CBI DDRC, PC5 ;definiendo entrada
	//LEDS portB
	SBI DDRB, PB0 ;definiendo pb5 como salida (led 4)
	SBI DDRB, PB1 ;definiendo pb4 como salida (led 3)
	SBI DDRB, PB2 ;definiendo pb3 como salida (led 2)
	SBI DDRB, PB3 ;definiendo pb2 como salida (led 1)
	LDI R16, 0
	OUT PORTB, R16
	//DISPLAY portD
	SBI DDRD, PD0 ;A
	SBI DDRD, PD1 ;B
	SBI DDRD, PD2 ;C
	SBI DDRD, PD3 ;D
	SBI DDRD, PD4 ;E
	SBI DDRD, PD5 ;F
	SBI DDRD, PD6 ;G
	LDI R16, 0
	OUT PORTD, R16
	//configurando instrucción
	//LDI R16, (1 << ISC01)
	//LDI R16, (1 << ISC00)
	//STS EICRA, R16 ;configura que la interrupcion (INT0) se activa en el flanco de reloj positivo
	LDI R16, PCIE0
	STS PCICR, R16  ;habilitar interrupciones en i/o
	LDI R16, PCINT0
	SBI PCMSK0, R16 ;habilitar interrupcion pcint0
	LDI R16, PCINT1
	SBI PCMSK0, R16 ;habilitar interrupcion pcint1
	LDI R16, TOIE0
	SBI TIMSK0, R16 ;habilitar interrupcion timer0
	//HABILITAR INTERRUPCION TIMER0
	LDI R17, 0 ;establecer valores iniciales
	LDI R18, 0
	LDI R16, 0
	LDI R19, 0x7E ;mostrar en 0 el display
	SEI ;habalitar interrupciones
	RJMP LOOP

TIMER0:
	LDI R16, (1 << CS02) | (1 << CS00) ;configurar el prescaler a 1024 para un reloj de 2M
	OUT TCCR0B, R16
	LDI R16, 236 ;valor de desbordamiento 10ms
	OUT TCNT0, R16
	RET

LOOP:
	OUT R16, PORTB ;mostrar valor de contador en los leds
	OUT R19, PORTD ;mostrar valor en display
	CALL DISPLAY
	CPI R17, 100
	BRNE LOOP
	LDI R17, 0
	INC R18
	CPI R18, 15
	BRNE LOOP
	LDI R18, 0
	RJMP LOOP

tabla7seg: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x73, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

DISPLAY:
	LDI ZH, HIGH(tabla7seg << 1)
	LDI ZL, LOW(tabla7seg << 1)
	ADD ZL, R18
	LPM R19, Z
	RET
ISR_PCINT0:
	//PUSH R16 ;guardar en la pila el registro r16
	//IN R16, SREG
	//PUSH R16 ;guardar en la pila el registro sreg
	INC R16
	//POP R16 ;recuperar el valor de sreg
	//OUT SREG, R16 ;guardar los valores antiguos de sreg
	//POP R16 ;guardar los valores antiguos de r16
	RETI
ISR_PCINT1:
	DEC R16
	RETI

ISR_TIMER0_OVF:
	INC R17
	LDI R16, 236 ;valor de desbordamiento 10ms
	OUT TCNT0, R16
	SBI TIFR0, TOV0 ;apagar bandera
	RETI