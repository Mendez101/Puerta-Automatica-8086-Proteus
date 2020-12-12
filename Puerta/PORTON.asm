#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=0FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

vars:
strlen db 0
empty db '0'
full db '2000'
count dw 0

;Ok  


;Puertos
ports: 
inputs equ 02h    ;indica la operacion que coloca al cursor,  
lcd_data equ 00h  ;Leer caracteres, 
lcd_motor_control equ 04h
creg_io equ 06h
porta2 equ 10h
portb2 equ 12h
creg2 equ 16h
timer_clock equ 08h  ;Registro igual aun segmento de codigo 
timer_remote equ 0Ah 
timer_door equ 0Ch
creg_timer equ 0Eh
jmp     st1
db     1024 dup(0)


st1:
mov al,10000000b
out creg_io,al
mov al, 00110100b
out creg_timer, al
mov al, 0A8h
out timer_clock, al
mov al, 61h
out timer_clock, al



startup:

 
 
garage_is_closed:
in al, inputs
and al, 00000001b
cmp al, 1
je open_the_garage_door
jmp garage_is_closed   


garage_to_open:
mov ah, 0                   
in al, inputs
mov bl, al
and bl, 00000001b
cmp bl, 00000001b           ; comprobar si hay alguna pulsacion remota
je close_the_garage_door
mov bl, al
and bl, 00010000b
cmp bl, 00010000b           ; comprobando si el temporizador
je close_the_garage_door
jmp garage_to_open 
 

close_the_garage_door:
motor_clockwise
start_door_timer
garage_door_is_still_closing:
in al, inputs
and al, 00100000b
cmp al, 00100000b       ; esperando hasta que la puerta se cierre completamente
jne garage_door_is_still_closing
stopping_the_motor
jmp garage_is_closed  


   
   

open_the_garage_door:
start_remote_timer
motor_anticlockwise    ;sentido antihorario
start_door_timer
the_door_is_still_open:  ;la puerta sigue abierta
in al, inputs
and al, 00100000b
cmp al, 00100000b       ; esperando hasta que la puerta se abra completamente
jne the_door_is_still_open
stopping_the_motor 
jmp garage_to_open


   
entering:
in al, inputs
mov bl, al
and bl, 00000001b
cmp bl, 00000001b           ; comprobar si hay pulsacion remota
je close_the_garage_door
mov bl, al
and bl, 00010000b
cmp bl, 00010000b           ; comprobando que el temporizador termine su tiempo de espera de 5 minutos
je close_the_garage_door



macros:     
;Contra agujas del reloj
motor_anticlockwise macro
in al, lcd_motor_control
and al, 11111100b
or al, 00000010b
out lcd_motor_control, al
endm
;Con agujas del reloj
motor_clockwise macro
in al, lcd_motor_control
and al, 11111100b
or al, 00000001b
out lcd_motor_control, al
endm
;Detemer el motor
stopping_the_motor macro
in al, lcd_motor_control 
and al, 11111100b
or al, 00000000b
out lcd_motor_control, al
endm
;iniciar temporizador remoto
start_remote_timer macro
mov al, 01110000b
out creg_timer, al
mov al, 30h
out timer_remote, al
mov al, 75h
out timer_remote, al
endm       

;iniciar temporizador de puerta
start_door_timer macro
		mov al, 10110000b
 		out creg_timer, al
		mov al, 0F4h
		out timer_door, al
		mov al, 01h
		out timer_door, al
endm

set_the_LCD_mode macro
		in al, lcd_motor_control
		and al, 00011111b
		or al, bl
		out lcd_motor_control, al
endm
      
      
      
lcd_putch macro
		push ax
		out lcd_data,al
		mov bl,10100000b
set_the_LCD_mode
		mov bl,10000000b
set_the_LCD_mode
		pop ax
		endm

putstring_on_LCD macro
		mov ch,0
		mov cl, strlen
putting:
		mov al, [di]
lcd_putch
		inc di
		loop putting
endm

     
     
procs:
		display_on_LCD proc near
		ret
		loaded:
		putstring_on_LCD
		ret
		display_on_LCD endp

