;--------------------------------------------------------------------------------------
; QDEL.COM
;
; Delete a file, quietly
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; read the command line, skip leading whitespace
		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		dec	si

; and then NUL-terminate the line
		mov	bl,[0x80]
		xor	bh,bh
		add	bl,0x81
		mov	byte [bx],0

; SI is still the (now ASCIIZ) string
		cmp	byte [si],0	; is it NULL-length?
		jnz	do_mkdir
		mov	dx,str_need_param
		call	puts
		ret			; return to DOS

; do the file deletion
do_mkdir:	mov	dx,si		; DS:DX = name of dir to make
		mov	ah,0x41		; AH=0x41 Delete file
		mov	cx,0		; CX=file attributes
		int	21h

; EXIT to DOS
exit_err:	ret			; TODO: If the error is anything other than "file does not exist" print error message

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'

		segment .bss

filehandle:	resw	1

