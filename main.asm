$NOMOD51
$INCLUDE (8051.MCU)

den1 				equ 		30H
den2 				equ 		31H
red1 				equ 		32H		; bien thoi gian den do cua block 1
yellow1 			equ 		33H		; bien thoi gian den vang cua block 1
green1 				equ 		34H		; bien thoi gian den xanh cua block 1
red2 				equ 		35H		; bien thoi gian den do cua block 2
yellow2 			equ 		36H		; bien thoi gian den vang cua block 2
green2 				equ 		37H		; bien thoi gian den xanh cua block 2
BCDinput 			equ 		38H		; bien dau vao cua ham BCD
BCDoutput1 			equ 		39H		; bien dau ra hang chuc cua ham BCD
BCDoutput2 			equ 		3AH		; bien dau ra hang don vi cua ham 
i1 					equ 		3BH		; bien dem thoi gian
time1 				equ 		3CH		; bien tam luu thoi gian cua block 1
time2 				equ 		3DH		; bien tam luu thoi gian cua block 2
Keycode				equ 		3Eh		; bien luu gia tri nhap tu keypad
COl 				equ			3Fh		; bien luu vi tri cua cot khi nhap tu keypad
temp_time			equ			R2		; bien tam luu gia tri thoi gian nhap vao
current_color_dur	equ			40H		; bien tam luu thoi gian nhap vao tu keypad
BCD_output			equ			41H
DEFAULT_RED_DUR		equ			24
DEFAULT_YELLOW_DUR	equ			03
DEFAULT_GREEN_DUR	equ			21

col1				bit			P2.0
col2				bit			P2.1
col3				bit 		P2.2
col4				bit 		P2.3
rowA				bit			P2.4
rowB				bit 		P2.5
rowC				bit			P2.6
rowD				bit			P2.7

	org 0f000h
Key_RowA:			db			07h, 08h, 09h, 0Ah
Key_RowB:			db			04h, 05h, 06h, 0Bh
Key_RowC:			db			01h, 02h, 03h, 0Ch
Key_RowD:			db			0Dh, 00h, 0Eh, 0Fh


	org 	0000H
	ljmp 	Start
	org 	0003h
	ljmp 	INTERRUPT0
	org 	001BH
	ljmp 	Timer1_ISR

	org 	0030H
Start:
      mov 		TMOD, #11H
      mov 		IE, #89H
      setb 		IT0
      call		Default

Config:   						; Ham nhap thoi gian cho den
      mov 		p1,#00001100B
	  anl		p0, #0Fh		; bat cac bit D1 D2 cua 2 LED len 1
	  mov		A, green1
	  add		A, yellow1
	  mov		red1, A
      mov 		red2, red1
      mov 		yellow2, yellow1
      mov 		green2, green1
      mov 		den1, #11111100B
      mov 		den2, #11001111B
      mov 		R0, #green1
      mov 		R1, #red2
	  mov 		time1, @R0
      mov 		time2, @R1
      call 		Count1s
Loop:
	mov		R5, time2
	acall	InputBlock
Block2d:						; Hien thi hang don vi cua LED 2
	mov			A, p0
    orl  		A, BCDoutput2
    mov 		p0, A
    setb		p0.7
	setb		p3.0
    call 		Delay
	clr			p3.0
    clr 		p0.7
    call 		ClearBlock
Block2c:						; Hien thi hang chuc cua LED 2
      mov 		A, p0
      orl  		A, BCDoutput1
      mov 		p0,A
      setb 		p0.6
	  setb		p3.0
      call 		Delay
	  clr		p3.0
      clr 		p0.6
      call 		ClearBlock

InputBlock1:						; Nhap vao thoi gian cho block 1				
	mov		R5, time1
	acall	InputBlock
Block1d:						; Hien thi hang don vi cua LED 1
      mov		A, p0
      orl  		A, BCDoutput2
      mov 		p0, A
      setb		p0.5
	  setb		p3.0
      call 		Delay
	  clr		p3.0
      clr 		p0.5
      call 		ClearBlock   
Block1c:						; Hien thi hang chuc cua LED 1
      mov 		A, p0
      orl 		A, BCDoutput1
      mov 		p0, A
      setb 		p0.4
	  setb		p3.0
      call 		Delay
	  clr		p3.0
      clr 		p0.4
      call 		ClearBlock

      jb 		TR1, Loop		; Cho phep duoc su dung keypad hay khong
      ljmp 		Keypad_handling
      jmp 		Config

InputBlock:;{
	; chuyen doi tu co so 10 sang so BCD
    mov 		A, R5
    mov 		B, #10
    div 		AB
    mov 		BCDoutput1, A
	
	mov			BCDoutput2, B
	ret
;}
;------------------------------------------------------------------

Delay:							; Ham delay bang vong lap
	mov			R3, #16
LoopD:
	mov			R4, #200
	djnz		R4, $
	djnz		R3, LoopD
	ret
      
;------------------------------------------------------------------

Count1s:						; Timer1 10ms
      mov 		i1,#100
      mov 		TL1,#000H
      mov 		TH1,#0DCH
      setb 		TR1 
      ret
      
;------------------------------------------------------------------
      
Timer1_ISR:						; Interrupt Timer1 dem 1s, kiem tra thoi gian cac den
      mov 		TL1, #00H
      mov 		TH1, #0dcH
	  setb 		TR1
      djnz 		i1, End_Count1s
      dec 		time1
      dec 		time2
      mov 		i1, #100
      call 		Check1
      call 		Check2
End_Count1s:
      reti

;------------------------------------------------------------------
      
;------------------------------------------------------------------


Check1:							; ham kiem tra thoi gian con lai cua den giao thong
	mov 		A, time1
	jnz 		EndCheck1
	call 		Color1
EndCheck1:
	ret
      
;------------------------------------------------------------------
      
Color1:							; ham chuyen doi mau cua den giao thong
      call 		Set1
      mov 		A, den1
      clr 		ACC.3
      rr 		A
      jb 		ACC.7, SetGreen1
      setb 		ACC.7
      mov 		den1, A
      mov 		A, p1
      anl  		A, den1
      mov 		p1, A
      dec 		R0
EndColor1:
      mov 		time1, @R0
      ret
      
;------------------------------------------------------------------  

SetGreen1:						; ham doi sang den mau xanh neu truoc do la mau do
      mov 		den1, #11111100B
      call 		Set1
      mov 		A, p1
      anl  		A, den1
      mov 		p1, A
      mov 		R0, #green1
      jmp 		EndColor1     
      
;------------------------------------------------------------------      

Check2:
      mov 		A, time2
      jnz		EndCheck2
      call 		Color2
EndCheck2:
      ret
      
;------------------------------------------------------------------

Color2:
      call 		Set2
      mov 		A, den2
      clr 		ACC.6
      rr 		A
      jb 		ACC.2, SetGreen2
      setb 		ACC.2
      mov 		den2, A
      mov 		A, p1
      anl  		A, den2
      mov 		p1, A
      dec 		R1
EndColor2:
      mov 		time2, @R1
      ret
      
;------------------------------------------------------------------  

SetGreen2:
    mov 		den2, #11100111B
	call 		Set2
	mov 		A, p1
	anl  		A, den2
	mov 		p1, A
	mov 		R1, #green2
	jmp 		EndColor2
      
;------------------------------------------------------------------  
 
ClearBlock:						; tat man hinh hien thi led
	mov			A, p0
	anl			A, #0F0h
	mov			p0, A
    ret

;------------------------------------------------------------------

Set1:
	setb 		p1.0
	setb 		p1.1
	setb		p1.2
	ret
      
;------------------------------------------------------------------

Set2:
	setb		p1.3
	setb		p1.4
	setb		p1.5
    ret
      
;------------------------------------------------------------------
Keypad_handling:
	clr		rowA   				; keo cac hang xuong muc thap
	clr		rowB				; ==> phat hien su kien nhan phim
	clr 	rowC				
   	clr		rowD
	jnb		col1,scan			; kiem tra bat ki cot nao duoc nhan
	jnb		col2,scan
	jnb		col3,scan
	jnb		col4,scan
	ljmp 	Loop

scan:							; neu co phim duoc nhan bat dau tim vi tri phim
	acall		delay				; chong doi phim 
	acall		scan_keypad	
	mov		A, Keycode

	; switch(Keycode)
	cjne		A, #0ah, not_0ah		
	jmp 		rst				; case 0ah (dau chia)
	
not_0ah:						
	cjne		A, #0bh, not_0bh
	call 		Default				; case 0bh (dau nhan): set ve gia tri mac dinh
	jmp 		rst
not_0bh:
	cjne		A, #0ch, not_0ch
	jmp 		rst				; case 0bh (dau tru)
	
not_0ch:
	cjne		A, #0fh, not_0fh
chooseColorKeypad:					; case 0fh (dau cong): chon loai den muon chinh thoi gian
	mov		A, p1
	cjne	A, #00100100B, greenKeypad
	mov 	p1,#00010010B
	mov		current_color_dur,#yellow1
	jmp		EndchooseColorKeypad
greenKeypad:
	RL		A
	mov		p1, A
	inc		current_color_dur
EndchooseColorKeypad:
	mov 	time1, #0
	mov 	time2, #0
	jmp 	rst 

not_0fh:
	cjne	A, #0dh, not_0dh
	mov		COL, #0
	jmp		Config							; case 0dh (nut ON): ket thuc viec nhap tu keypad
	
not_0dh:
	cjne	A, #0Eh, not_0eh
SetTime:						; case 0eh (dau bang): xac nhan thoi gian thay doi
	mov 	A, current_color_dur
	cjne	A, #33H, TimeGreen
	mov		yellow1, temp_time
	jmp		endSetTime
TimeGreen:
	mov		green1, temp_time
endSetTime:
	jmp		rst
	
not_0eh:						; case default: nhap tu cac phim tu 0->9 de tinh toan
	acall	store_time
rst:
	mov		COl, #0				; reset trang thai sau khi hien thi
	jmp 	Keypad_handling

; kiem tra va xac dinh vi tri Cot cua phim khi thuc hien quet phim
check_col:
	jb		col1, check_col2
	mov		COL, #1			  	; co phim o Cot 1 duoc nhan
	ret
check_col2:
	jb		col2, check_col3
	mov		COL, #2				; Cot 2
	ret
check_col3:
	jb		col3, check_col4
	mov		COL, #3				; Cot 3
	ret
check_col4:
	jb		col4, finish
	mov		COL, #4				; Cot 4
finish:
	ret

; quet phim
scan_keypad:
	clr		rowA  				; quet hang A
	setb	rowB
	setb	rowC
	setb	rowD
	acall	check_col			; kiem tra co phim nao cua hang A duoc nhan hay khong
	mov		A,COL				; tra ve vi tri Cot cua phim duoc nhan
	jz		to_rowB				; nhay sang quet hang tiep theo neu khong co phim nao cua hang A duoc nhan
	mov		DPTR, #Key_RowA		; luu cac phim cua hang A neu co phim trong hang duoc nhan
	sjmp	asign_keycode
to_rowB:
	clr		rowB
	setb	rowA
	setb	rowC
	setb	rowD
	acall	check_col
	mov		A,COL
	jz		to_rowC
	mov		DPTR, #Key_RowB
	sjmp	asign_keycode
to_rowC:
	clr		rowC
	setb	rowB
	setb	rowA
	setb	rowD
	acall	check_col
	mov		A,COL
	jz		to_rowD
	mov		DPTR, #Key_RowC
	sjmp	asign_keycode
to_rowD:
	clr		rowD
	setb	rowB
	setb	rowC
	setb	rowA
	acall	check_col
	mov		A,COL
	jz		ok
	mov		DPTR, #Key_RowD
asign_keycode:					; gan gia tri phim
	setb	C
	anl		C, col1
	anl		C, col2
	anl		C, col3
	anl		C, col4
	jnc		asign_keycode
	add		A,#-1				; tru vi tri cot di 1
	movc	A, @A + DPTR		; gan gia tri phim tai o nho A + DPTR cho thanh ghi A
	mov		Keycode, A			; luu lai gia tri phim
ok:
	ret
	
INTERRUPT0:
	clr			TR1
	lcall		start_keypad
	reti

start_keypad:						; ham cho phep su dung keypad
	clr 		p0.7
	clr 		p0.6
	clr 		p0.5
	clr 		p0.4
	mov 		p1, #00010010B
	mov 		time1, #0
	mov 		time2, #0
	mov 		current_color_dur, #yellow1
	ret

store_time:;{
	mov		R2, A
	mov		A, time1
	jz		store
	cjne	A, #10, next0
	next0:
	jc		next1
	mov		B, #10
	div		AB
	mov		A, B
	next1:
	mov		B, #10
	mul		AB
	store:	
	add		A, R2
	mov 	time1,A
	mov		time2,A
	mov		R2, A
	ret
;}
Default:						; ham dat gia tri mac dinh
	 mov 		red1, #DEFAULT_RED_DUR
	 mov 		yellow1, #DEFAULT_YELLOW_DUR
	 mov 		green1, #DEFAULT_GREEN_DUR
	 ret
END