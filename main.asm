;snake game clone
;written by Mathewnd

;do whatever you want with this code lol
;I'm not responsible for anything you do with it

empty_tile_char   equ '@'
snake_char        equ '%'
fruit_char        equ '#'
snake_colour      equ 2
empty_tile_color  equ 8

game_data   equ 0x50
;bit 7 set = not empty
;bits 0-1  = direction


[bits 16] ; real mode

;set up DS, SS and SP
cli
mov ax,0x7C0
mov ds,ax
mov ax,0x1000
mov ds,ax
mov sp,0xFFF0
sti

;set up the video mode
xor ah,ah  ; SET VIDEO MODE
mov al,0x3 ; 80x25 16 color text
int 10h

;fill out the empty tiles with the emtpy tile character

mov cx,2000

fill_empty_tiles:

push cx

mov al,empty_tile_char
mov ah,empty_tile_color ; brown colour with black background
dec cx
call write_char

pop cx

loop fill_empty_tiles

call make_fruit

mov  cx,1 ;not eaten
push cx   ;set this to not glitch the loop later

main_loop:

call game_wait

;copy the player direction data for use in input

mov dl, [player_data]
and dl,0b00000011 ;zero everything but the direction bits
mov [input_player_data_copy], dl

.get_input:

;get player input

mov dh,[player_data] ;load player data
and dh,0b11111100 ;zero the direction bits

mov ah,1 ; get keyboard status
int 16h
jz .input_done

;clean buffer

xor ah,ah
int 16h 

;save the direction in a register for checking

mov dl,[input_player_data_copy]

cmp ah,0x50
je .down_arr
cmp ah,0x48
je .up_arr
cmp ah,0x4B
je .left_arr

;right arrow

cmp dl,0b01
je .input_process_done

jmp .input_change

.left_arr:

test dl,dl
jz .input_process_done

or  dh,0b00000001

jmp .input_change

.up_arr:

cmp dl,0b10
je .input_process_done

or  dh,0b00000011

jmp .input_change

.down_arr:

cmp dl,0b11
je .input_process_done

or  dh,0b00000010

.input_change:

mov [player_data],dh

.input_process_done:


jmp .get_input

.input_done:
;get player and entry data into registers

mov bx,game_data
mov es,bx
mov bx,[player_pos]
mov dh,[es:bx]
mov dl,[player_data]

;set the direction on the map entry for later use

and dl,0b00000011
and dh,0b11111100
or  dh,dl
or  dh,0b10000000 ; set the "not empty" bit

mov [es:bx],dh

mov dh,[player_data]
mov cx,[player_pos]

push cx ;save for later

;call the subroutine to do the moving

call pos_move

;check if hitting the top or down borders
cmp cx,1999
ja lose


;check if horizontal borders were hit

pop dx
push cx

mov bx,80 ; we will divide them by 80 to get the remainder

mov ax,dx
xor dx,dx
div bx
push dx

mov ax,cx
xor dx,dx
div bx

pop bx

cmp bx,79
je .check_79
test bx,bx
jz .check_00

jmp .check_end

.check_00:

cmp dx,79
je lose

jmp .check_end

.check_79:

test dx,dx
jz lose

.check_end:

;check if non empty (was supposed to be another way, but I just did it this way as a lazy fix to a problem)

pop cx

mov bx,0xb800
mov es,bx
mov bx,cx
shl bx,1

mov ax,[es:bx]
cmp al,snake_char
je lose

;save the new pos

mov [player_pos], cx

;update graphics

mov al, snake_char
mov ah, snake_colour

call write_char

;check if a fruit was eaten

pop cx
test cx,cx
jnz .has_not_eaten

;jump to checks

jmp .checks

;not eaten

.has_not_eaten:

mov ax,[seg_count]
test ax,ax
jnz .more_than_one_seg


;one segment

mov cx,[last_segment]

push cx ; save for graphics

mov cx,[player_pos]
mov [last_segment],cx

jmp .last_segment_finish

.more_than_one_seg:


;get the data for the last segment

mov cx, [last_segment]

mov bx,game_data 
mov es,bx
mov bx,cx

mov dh,[es:bx]

and dh,0b01111111 ;unset the "not empty" bit

mov [es:bx],dh

push cx ; save for use in graphics updating

call pos_move ; call the subroutine to do the moving

mov [last_segment], cx ;save the new last pos

.last_segment_finish:

;update graphics

pop cx

mov al, empty_tile_char
mov ah, empty_tile_color

call write_char

.checks:

;check for fruit

mov ax,[fruit_data]
mov bx,[player_pos]

cmp ax,bx

jne .not_eat

;eat

call make_fruit

mov cx,[seg_count]
inc cx
mov [seg_count],cx

xor cx,cx ;set cx to eaten

jmp .eat_done


.not_eat:
mov cx,1 ;set cx to not eaten

.eat_done:

push cx ; push into stack for later use



jmp main_loop


;transforms position and direction into a new position

;cx = pos
;dh = direction flag (bits 0-1)

;returns cx as new pos

;changes the values of ax and dx

pos_move:

mov dl,dh

and dl,0b00000001
and dh,0b00000010
jnz .vertical

;horizontal

; pos += 1 - 2*direction_flag

inc cx
shl dl,1
sub cx,dx

jmp .return

.vertical:

;pos += 80 - 160*direction_flag

add cx,80
mov ax,160
mul dl
sub cx,ax

.return:

ret

;####################################


;creates a new fruit

make_fruit:

;get the position to place the fruit at.


xor ah,ah ;read system clock counter
int 1Ah 

;turn the lower word of the count into the position


mov ax,dx ; get ax % 2000
xor dx,dx
mov cx,2000
div cx

mov cx,dx
mov [fruit_data],cx

;make the fruit appear in the screen

mov al,fruit_char
mov ah,4 ; red colour with black background
xor dx,dx
call write_char

ret


;######################################################

;writes character and colour (ax) at (cx) 

;al = character
;ah = colour, etc.

write_char:

;multiply cx by 2 cause the entries are words and not bytes

shl cx,1

;now that we have the offset, set ES:BX to the adress of the entry to change

mov bx,0xB800
mov es,bx ; set ES To the adress
mov bx,cx ;put the offset on bx

mov [es:bx],ax ; set the entry

ret

;#############################################################


lose:

cli
hlt

;############################################

;halts the program for around a second

game_wait:

xor ah,ah ; READ SYSTEM CLOCK COUNTER
int 1Ah

;store the low word of the tick count on the BX register
mov bx,dx

.loop:
;see if 1 timer ticks have passed
;ah is already set to 00
int 1Ah

;get the difference
sub dx, bx

cmp dx,1

;if >= 1 then jump to .done
ja .done
;else jump to .loop
jmp .loop

.done:
ret

;-----------------------------------------------

;    DATA

input_player_data_copy: db 0
player_data: db 0 ; 000000-00 bits 0-1 are the direction bits

;direction:
;00 - right
;01 - left
;10 - down
;11 - up

player_pos: dw 1000

last_segment: dw 1000

fruit_data:  dw 0

seg_count:   db 0


;pad out the binary file to make it a bootable sector
times 510-($-$$) db 0
dw 0xAA55 ; boot signature