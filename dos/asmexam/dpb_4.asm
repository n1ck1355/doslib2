;--------------------------------------------------------------------------------------
; DPB_4.COM
;
; Ask DOS for the Disk Parameter Block.
; Note the DPB changed slighly from version to version up until DOS 4.0/5.0, which is
; why this version specializes in DOS 4.0 or higher.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x30
		int	21h		; GET DOS VERSION
		cmp	al,4		; must be DOS 4.0 or higher
		jae	version_ok

		mov	dx,need_dos_version
		jmp	common_str_error

version_ok:	mov	ah,0x32		; AH=0x32 GET DOS DRIVE PARAM BLOCK
		xor	dl,dl		; DL=0 default drive
		int	21h
		cmp	al,0		; did it succeed?
		jz	request_ok

		mov	dx,str_req_fail
		jmp	short common_str_error

; it worked! DOS set DS:BX to point at the DPB
request_ok:	push	ds		; move DS to ES
		pop	es
		push	cs		; restore DS == CS
		pop	ds

;----------- DRIVE
		mov	dx,str_drive_number
		call	common_str_print

		mov	al,[es:bx]	; +0x00 drive number
		add	al,'A'
		call	putc

		mov	dx,crlf
		call	common_str_print

;----------- UNIT WITHIN DRIVER
		mov	dx,str_unit_number
		call	common_str_print

		mov	al,[es:bx+1]	; +0x01 unit within device driver
		xor	ah,ah
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- BYTES PER SECTOR
		mov	dx,str_bytes_per_sector
		call	common_str_print

		mov	ax,[es:bx+2]	; +0x02 bytes per sector
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- Highest sector number in a cluster
		mov	dx,str_highest_sector_num_cl
		call	common_str_print

		mov	al,[es:bx+4]	; +0x04 highest sector in a cluster
		xor	ah,ah
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- Sectors per cluster
		mov	dx,str_sectors_per_cluster_pow2
		call	common_str_print

		mov	cl,[es:bx+5]	; +0x05 shift count to convert clusters to sectors
		mov	ax,0x200
		shl	ax,cl
		call	putdec16

		mov	dx,crlf
		call	common_str_print

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
		hlt

; print error message in DS:DX and then exit to DOS
common_str_error:mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h
		jmp	exit

common_str_print:push	ax
		push	bx
		push	dx
		mov	ah,0x09
		int	21h
		pop	dx
		pop	bx
		pop	ax
		ret

common_str_print_crlf:push	ax
		push	bx
		push	dx
		mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h
		pop	dx
		pop	bx
		pop	ax
		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
putdec16:	push	ax
		push	bx
		push	cx
		push	dx

		xor	dx,dx
		mov	cx,1
		mov	bx,10
		div	bx
		push	dx

putdec16_loop:	test	ax,0xFFFF
		jz	putdec16_pl
		xor	dx,dx
		inc	cx
		div	bx
		push	dx
		jmp	short putdec16_loop

putdec16_pl:	xor	bh,bh
putdec16_ploop:	pop	ax
		mov	bl,al
		mov	al,[bx+hexes]
		call	putc
		loop	putdec16_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
puthex8:	push	ax
		push	bx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes]
		call	putc
		pop	bx
		pop	ax
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
str_req_fail:	db	'Request failed$'
need_dos_version:db	'This version requires MS-DOS 4.0 or higher$'
str_drive_number:db	'Drive: $'
str_unit_number:db	'Unit: $'
str_bytes_per_sector:db	'Bytes/sector: $'
str_highest_sector_num_cl:db 'Highest sector number in a cluster: $'
str_sectors_per_cluster_pow2:db 'Sectors/cluster: $'
crlf:		db	13,10,'$'

		segment .bss

