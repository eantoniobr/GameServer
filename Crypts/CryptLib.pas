unit CryptLib;

interface

uses Windows, Crypts, System.SysUtils;

function _memcpy(dest, src: PAnsiChar; size_t: integer): Cardinal; cdecl;
  external 'msvcrt.dll' name 'memcpy';

function _malloc(size_t: integer): PAnsiChar; cdecl;
  external 'msvcrt.dll' name 'malloc';

function _free(memblock: pansichar): Cardinal; cdecl;
  external 'msvcrt.dll' name 'free';

function _memset(dest: PAnsichar; c, size_t: integer): Cardinal; cdecl;
  external 'msvcrt.dll' name 'memset';

type
  TCrypt = Class
    private
      function DecryptS(const data: AnsiString; key: Integer): AnsiString;
      function EncryptS(const data: AnsiString; key: Integer): AnsiString;
      function Compress(const data: AnsiString): AnsiString;
      function Create3Bytes(srcSize: Integer): Integer;
      function returnsize(const what: AnsiString): integer;
    public
      function Encrypt(const data : AnsiString; Key : Byte): AnsiString;
      function Decrypt(const data : AnsiString; Key : Byte): AnsiString;
  End;

implementation

{ TCrypt }

function TCrypt.Compress(const data: AnsiString): AnsiString;
var
  size, bytesreservados, temp3: integer;
  temp, temp2, indc: PAnsiChar;
  src, hex: AnsiString;
begin
  bytesreservados:=Length(data);
  src:=data;
  temp:=AllocMem(Length(src)*4);
  _memcpy(temp,PAnsiChar(src),Length(src));
  temp2:=AllocMem(Length(src)*4);
  indc:=AllocMem(100000);
  size:=length(data);
asm
  push indc
  lea ecx, size
  push ecx
  push temp2
  push size
  push temp
  call @pre
  add esp, 14h
  jmp @end
  @pre:
    push ebp
    mov ebp, esp
    push ecx
    mov eax, dword ptr ss:[ebp+0ch]
    mov ecx, dword ptr ss:[ebp+10h]
    push ebx
    push esi
    push edi
    mov edi, dword ptr ss:[ebp+8]
    mov esi, ecx
    cmp eax, 0dh
    ja @jmp1a
    mov ebx, eax
    jmp @jmp2a
    @jmp1a:
      mov edx, dword ptr ss:[ebp+18h]
      mov esi, dword ptr ss:[ebp+14h]
      push edx
      push esi
      push ecx
      push edi
      call @after
      mov esi, dword ptr ds:[esi]
      add esi, dword ptr ss:[ebp+10h]
      mov ecx, dword ptr ss:[ebp+10h]
      mov ebx, eax
      mov eax, dword ptr ss:[ebp+0ch]
    @jmp2a:
      test ebx, ebx
      je @jmp3a
      sub edi, ebx
      add edi, eax
      mov dword ptr ss:[ebp-4], edi
      cmp esi, ecx
      jnz @jmp4a
      cmp ebx, 0eeh
      ja @jmp4a
      lea eax, dword ptr ds:[ebx+11h]
      jmp @jmp5a
    @jmp4a:
      cmp ebx, 3
      ja @jmp6a
      or byte ptr ds:[esi-2], bl
      jmp @jmp7a
    @jmp6a:
      cmp ebx, 12h
      ja @jmp8a
      lea edx, dword ptr ds:[ebx-3]
      mov byte ptr ds:[esi], dl
      jmp @jmp9a
    @jmp8a:
      lea eax, dword ptr ds:[ebx-12h]
      mov byte ptr ds:[esi], 0
      inc esi
      mov dword ptr ss:[ebp+0ch], eax
      cmp eax, 0ffh
      jbe @jmp5a
      lea ecx, dword ptr ds:[eax-100h]
      mov eax, 80808081h
      mul ecx
      mov edi, edx
      shr edi, 7
      inc edi
      push edi
      push 0
      push esi
      call _memset
      add esp, 0ch
      add esi, edi
    @jmp1a0:
      sub dword ptr ss:[ebp+0ch], 0ffh
      dec edi
      jnz @jmp1a0
      mov eax, dword ptr ss:[ebp+0ch]
      mov edi, dword ptr ss:[ebp-4]
      mov ecx, dword ptr ss:[ebp+10h]
    @jmp5a:
      mov byte ptr ds:[esi], al
    @jmp9a:
      inc esi
    @jmp7a:
      mov dl, byte ptr ds:[edi]
      mov byte ptr ds:[esi], dl
      inc esi
      inc edi
      dec ebx
      jnz @jmp7a
    @jmp3a:
      mov eax, dword ptr ss:[ebp+14h]
      mov word ptr ds:[esi], 11h
      add esi, 2
      mov byte ptr ds:[esi], 0
      sub esi, ecx
      inc esi
      pop edi
      mov dword ptr ds:[eax], esi
      pop esi
      xor eax, eax
      pop ebx
      mov esp, ebp
      pop ebp
      ret
    @after:
      db 055h, 08Bh, 0ECh, 083h, 0ECh, 01Ch, 053h, 056h, 08Bh, 075h, 00Ch, 057h, 08Bh, 07Dh, 008h, 08Dh, 00Ch, 007h, 089h, 07Dh, 0F8h, 089h, 04Dh, 0F0h, 083h, 0C7h, 004h, 0EBh, 003h, 08Dh, 049h, 000h
      db 00Fh, 0B6h, 047h, 003h, 00Fh, 0B6h, 057h, 002h, 00Fh, 0B6h, 04Fh, 001h, 0C1h, 0E0h, 006h, 033h, 0C2h, 00Fh, 0B6h, 017h, 0C1h, 0E0h, 005h, 033h, 0C1h, 0C1h, 0E0h, 005h, 033h, 0C2h, 08Bh, 055h
      db 014h, 08Bh, 0C8h, 0C1h, 0E1h, 005h, 003h, 0C1h, 0C1h, 0E8h, 005h, 025h, 0FFh, 03Fh, 000h, 000h, 08Bh, 01Ch, 082h, 08Dh, 00Ch, 082h, 03Bh, 05Dh, 008h, 00Fh, 082h, 07Fh, 002h, 000h, 000h, 08Bh
      db 0D7h, 02Bh, 0D3h, 089h, 055h, 0FCh, 04Ah, 089h, 07Dh, 0ECh, 089h, 055h, 0F4h, 081h, 0FAh, 0FEh, 0BFh, 000h, 000h, 00Fh, 087h, 065h, 002h, 000h, 000h, 081h, 07Dh, 0FCh, 000h, 008h, 000h, 000h
      db 076h, 050h, 08Ah, 057h, 003h, 038h, 053h, 003h, 074h, 048h, 08Bh, 04Dh, 014h, 025h, 0FFh, 007h, 000h, 000h, 035h, 01Fh, 020h, 000h, 000h, 08Bh, 01Ch, 081h, 08Dh, 00Ch, 081h, 03Bh, 05Dh, 008h
      db 00Fh, 082h, 038h, 002h, 000h, 000h, 08Bh, 0C7h, 02Bh, 0C3h, 08Dh, 050h, 0FFh, 089h, 045h, 0FCh, 089h, 055h, 0F4h, 081h, 0FAh, 0FEh, 0BFh, 000h, 000h, 00Fh, 087h, 01Fh, 002h, 000h, 000h, 03Dh
      db 000h, 008h, 000h, 000h, 076h, 00Ch, 08Ah, 047h, 003h, 038h, 043h, 003h, 00Fh, 085h, 00Ch, 002h, 000h, 000h, 066h, 08Bh, 013h, 066h, 03Bh, 017h, 00Fh, 085h, 000h, 002h, 000h, 000h, 08Ah, 047h
      db 002h, 038h, 043h, 002h, 00Fh, 085h, 0F4h, 001h, 000h, 000h, 08Bh, 055h, 0F8h, 08Bh, 0C7h, 02Bh, 0C2h, 089h, 039h, 074h, 077h, 089h, 045h, 0E4h, 083h, 0F8h, 003h, 077h, 005h, 008h, 046h, 0FEh
      db 0EBh, 05Eh, 083h, 0F8h, 012h, 077h, 005h, 08Dh, 048h, 0FDh, 0EBh, 04Ah, 08Dh, 048h, 0EEh, 0C6h, 006h, 000h, 046h, 089h, 04Dh, 0ECh, 081h, 0F9h, 0FFh, 000h, 000h, 000h, 076h, 038h, 081h, 0C1h
      db 000h, 0FFh, 0FFh, 0FFh, 0B8h, 081h, 080h, 080h, 080h, 0F7h, 0E1h, 0C1h, 0EAh, 007h, 042h, 052h, 06Ah, 000h, 056h, 089h, 055h, 0E8h
      call _memset
      db 08Bh, 045h, 0E8h, 083h, 0C4h, 00Ch, 003h, 0F0h, 081h, 06Dh, 0ECh, 0FFh, 000h, 000h, 000h, 048h, 075h, 0F6h, 08Bh, 04Dh, 0ECh, 08Bh, 045h, 0E4h, 08Bh, 055h, 0F8h, 088h, 00Eh, 046h, 08Dh, 0A4h
      db 024h, 000h, 000h, 000h, 000h, 08Ah, 00Ah, 088h, 00Eh, 046h, 042h, 048h, 075h, 0F7h, 089h, 055h, 0F8h, 08Ah, 047h, 003h, 083h, 0C7h, 004h, 038h, 043h, 003h, 00Fh, 085h, 0EBh, 000h, 000h, 000h
      db 08Ah, 00Fh, 047h, 038h, 04Bh, 004h, 00Fh, 085h, 0DFh, 000h, 000h, 000h, 08Ah, 007h, 047h, 038h, 043h, 005h, 00Fh, 085h, 0D3h, 000h, 000h, 000h, 08Ah, 00Fh, 047h, 038h, 04Bh, 006h, 00Fh, 085h
      db 0C7h, 000h, 000h, 000h, 08Ah, 007h, 047h, 038h, 043h, 007h, 00Fh, 085h, 0BBh, 000h, 000h, 000h, 08Ah, 00Fh, 047h, 038h, 04Bh, 008h, 00Fh, 085h, 0AFh, 000h, 000h, 000h, 08Bh, 045h, 0F0h, 083h
      db 0C3h, 009h, 03Bh, 0F8h, 073h, 00Ch, 08Ah, 013h, 03Ah, 017h, 075h, 006h, 047h, 043h, 03Bh, 0F8h, 072h, 0F4h, 08Bh, 045h, 0FCh, 08Bh, 0DFh, 02Bh, 05Dh, 0F8h, 03Dh, 000h, 040h, 000h, 000h, 077h
      db 022h, 08Bh, 045h, 0F4h, 089h, 045h, 0FCh, 083h, 0FBh, 021h, 077h, 00Fh, 080h, 0EBh, 002h, 080h, 0CBh, 020h, 088h, 01Eh, 08Bh, 0C8h, 0E9h, 0D1h, 000h, 000h, 000h, 083h, 0EBh, 021h, 0C6h, 006h
      db 020h, 0EBh, 02Ah, 02Dh, 000h, 040h, 000h, 000h, 089h, 045h, 0FCh, 0C1h, 0E8h, 00Bh, 024h, 008h, 083h, 0FBh, 009h, 077h, 011h, 08Bh, 04Dh, 0FCh, 080h, 0EBh, 002h, 00Ah, 0C3h, 00Ch, 010h, 088h
      db 006h, 0E9h, 0A6h, 000h, 000h, 000h, 083h, 0EBh, 009h, 00Ch, 010h, 088h, 006h, 046h, 081h, 0FBh, 0FFh, 000h, 000h, 000h, 076h, 02Eh, 08Dh, 08Bh, 000h, 0FFh, 0FFh, 0FFh, 0B8h, 081h, 080h, 080h
      db 080h, 0F7h, 0E1h, 0C1h, 0EAh, 007h, 042h, 052h, 06Ah, 000h, 056h, 089h, 055h, 0E4h
      call _memset
      db 08Bh, 045h, 0E4h, 083h, 0C4h, 00Ch, 003h, 0F0h, 081h, 0EBh, 0FFh, 000h, 000h, 000h, 048h, 075h, 0F7h, 08Bh, 04Dh, 0FCh, 088h, 01Eh, 0EBh, 061h, 08Bh, 04Dh, 0FCh, 04Fh, 08Bh, 0C7h, 02Bh, 0C2h
      db 081h, 0F9h, 000h, 008h, 000h, 000h, 077h, 026h, 08Bh, 04Dh, 0F4h, 0FEh, 0C8h, 002h, 0C0h, 002h, 0C0h, 002h, 0C0h, 08Ah, 0D1h, 080h, 0E2h, 007h, 00Ah, 0C2h, 002h, 0C0h, 002h, 0C0h, 0C1h, 0E9h
      db 003h, 088h, 006h, 088h, 04Eh, 001h, 083h, 0C6h, 002h, 089h, 07Dh, 0F8h, 0EBh, 045h, 02Ch, 002h, 081h, 0F9h, 000h, 040h, 000h, 000h, 077h, 00Ch, 08Bh, 04Dh, 0F4h, 00Ch, 020h, 089h, 04Dh, 0FCh
      db 088h, 006h, 0EBh, 015h, 081h, 0E9h, 000h, 040h, 000h, 000h, 08Bh, 0D1h, 0C1h, 0EAh, 00Bh, 080h, 0E2h, 008h, 00Ah, 0D0h, 080h, 0CAh, 010h, 088h, 016h, 08Ah, 0C1h, 002h, 0C0h, 046h, 002h, 0C0h
      db 0C1h, 0E9h, 006h, 088h, 006h, 088h, 04Eh, 001h, 083h, 0C6h, 002h, 089h, 07Dh, 0F8h, 0EBh, 003h, 089h, 039h, 047h, 08Bh, 045h, 0F0h, 083h, 0C0h, 0F3h, 03Bh, 0F8h, 00Fh, 082h, 031h, 0FDh, 0FFh
      db 0FFh, 02Bh, 075h, 00Ch, 08Bh, 04Dh, 010h, 08Bh, 045h, 0F0h, 02Bh, 045h, 0F8h, 05Fh, 089h, 031h, 05Eh, 05Bh, 08Bh, 0E5h, 05Dh, 0C2h, 010h, 000h
  @end:
end;
  setstring(result, pansichar(temp2), size);

  temp3 := Create3Bytes(bytesreservados);
  SetLength(hex, 4);
  Move(temp3, hex[1], 4);
  result := #$00#$00#$00#$00 + hex + result;

  FreeMem(temp);
  FreeMem(temp2);
  FreeMem(indc);
end;

function TCrypt.Create3Bytes(srcSize: Integer): Integer;
var
  m_Buffer, vresult: array[0..3] of byte;
  v11, v12: integer;
begin
  m_Buffer[3]:=trunc(srcSize+srcSize / 255);
  v11:=trunc((srcSize - m_Buffer[3]) / 255);
  m_Buffer[2]:=trunc(v11+v11 / 255);
  v12:=trunc((v11 - m_Buffer[2]) / 255);
  m_Buffer[1]:=trunc(v12+v12 / 255);
  ZeroMemory(@vresult,4);
  vresult[1]:=m_Buffer[1];
  vresult[2]:=m_Buffer[2];
  vresult[3]:=m_Buffer[3];
  result:=PInteger(@vresult)^;
end;

function TCrypt.Decrypt(const data: AnsiString; Key: Byte): AnsiString;
begin
  Result := DecryptS( data, Key);
end;

function TCrypt.DecryptS(const data: ansistring; key: Integer): AnsiString;
var
  storedspace: PAnsichar;
  size, factor: integer;
  src: AnsiString;
begin
  src:=data;
  storedspace:=AllocMem(Length(src)*2);
  factor:=byte(keys[(key shl 8)+byte(src[1])+1]);
  size:=returnsize(src[2]+src[3])+1;
  _memcpy(storedspace,pansichar(src),Length(src));
  asm
    mov ecx, storedspace
    add ecx, 4
    push factor
    push size
    mov edx, ecx
    call @decrypt
    jmp @end
    @decrypt:
      push ebp
      mov ebp, esp
      sub esp, 0ch
      push ebx
      push esi
      mov ebx, ecx
      mov esi, edx
      push edi
      mov edi, dword ptr ss:[ebp+8h]
      mov dword ptr ss:[ebp-0ch], ebx
      mov byte ptr ss:[ebp-1], 0
      cmp ebx, esi
      jnz @lab1
      push edi
      call _malloc
      add esp, 4
      mov esi, eax
      mov byte ptr ss:[ebp-1], 1
      @lab1:
        mov ecx, edi
        mov edx, edi
        shr ecx, 2
        and edx, 3
        mov dword ptr ss:[ebp-8], edx
        test ecx, ecx
        je @lab4
        mov eax, dword ptr ds:[ebx]
        xor eax, dword ptr ss:[ebp+0ch]
        mov dword ptr ds:[esi], eax
        cmp ecx, 1
        jbe @lab2
        mov edx, ebx
        lea edi, dword ptr ds:[ecx-1]
        lea eax, dword ptr ds:[esi+4]
        sub edx, esi
        mov dword ptr ss:[ebp+0ch], edi
      @loop1:
        mov edi, dword ptr ds:[edx+eax]
        xor edi, dword ptr ds:[eax-4]
        add eax, 4
        dec dword ptr ss:[ebp+0ch]
        mov dword ptr ds:[eax-4], edi
        jnz @loop1
        mov edx, dword ptr ss:[ebp-8]
        mov edi, dword ptr ss:[ebp+8]
      @lab2:
        add ecx, ecx
        add ecx, ecx
        mov eax, dword ptr ds:[ecx+esi-4]
        mov dword ptr ss:[ebp+0ch], eax
        mov eax, ecx
        jmp @lab3
      @lab4:
        mov ecx, dword ptr ss:[ebp+0ch]
        mov dword ptr ss:[ebp+0ch], ecx
        xor eax, eax
      @lab3:
        test edx, edx
        je @lab5
        mov ecx, dword ptr ss:[ebp-8h]
        mov edx, ebx
        add eax, esi
        xor edi, edi
        sub edx, esi
        mov dword ptr ss:[ebp-8h], ecx
      @loop2:
        mov ebx, dword ptr ss:[ebp+0ch]
        mov ecx, edi
        shr ebx, cl
        add edi, 8h
        inc eax
        xor bl, byte ptr ds:[eax+edx-1]
        dec dword ptr ss:[ebp-8h]
        mov byte ptr ds:[eax-1], bl
        jnz @loop2
        mov edi, dword ptr ss:[ebp+8h]
        mov ebx, dword ptr ss:[ebp-0ch]
      @lab5:
        push edi
        push esi
        push ebx
        call _memcpy
        add esp, 0ch
        cmp byte ptr ss:[ebp-1], 0
        je @lab6
        push esi
        call _free
        add esp, 4
      @lab6:
        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret 8h
    @end:
  end;
  setstring(result, pansichar(storedspace), Length(src));
  FreeMem(storedspace);
end;

function TCrypt.Encrypt(const data: AnsiString; Key: Byte): AnsiString;
begin
  Result := EncryptS( Compress(data), Key);
end;

function TCrypt.EncryptS(const data: AnsiString; key: Integer): AnsiString;
var
  storedspace: PAnsichar;
  sz, nrand, x, y: integer;
  size: word;
  src: AnsiString;
begin
  src := data;
  size := length(src) - 3;
  sz := size;
  randomize;
  nrand := random($FF);
  x := byte(keys[(key shl 8) + nrand + 1]);
  y := byte(keys[(key shl 8) + nrand + 4097]);
  src[1] := AnsiChar(nrand);
  src[4] := AnsiChar(y);
  storedspace := AllocMem(Length(src) * 2);
  _memcpy(storedspace, pAnsichar(src), Length(src));
  asm
        mov     bx, size
        mov     ecx, storedspace
        mov     word ptr ds:[ecx + 1], bx
        add     ecx, 3
        push    x
        push    sz
        mov     edx, ecx
        call    @crypt
        jmp     @END

@crypt:
        push    ebp
        mov     ebp, esp
        sub     esp, 0ch
        push    ebx
        push    edi
        mov     edi, ecx
        mov     ebx, edx
        mov     dword ptr ss:[ebp - 0ch], edi
        mov     byte ptr ss:[ebp - 1], 0
        cmp     edi, ebx
        jnz     @lab1
        mov     eax, dword ptr ss:[ebp + 8h]
        push    eax
        call    _malloc
        add     esp, 4
        mov     ebx, eax
        mov     byte ptr ss:[ebp - 1], 1

@lab1:
        mov     edx, dword ptr ss:[ebp + 8]
        mov     ecx, edx
        SHR     ecx, 2
        AND     edx, 3
        push    esi
        mov     dword ptr ss:[ebp - 8h], edx
        test    ecx, ecx
        je      @lab6
        mov     eax, dword ptr ds:[edi]
        XOR     eax, dword ptr ss:[ebp + 0ch]
        mov     dword ptr ds:[ebx], eax
        cmp     ecx, 1
        jbe     @lab2
        mov     edx, ebx
        lea     esi, dword ptr ds:[ecx - 1]
        lea     eax, dword ptr ds:[edi + 4]
        sub     edx, edi
        mov     dword ptr ss:[ebp + 0ch], esi

@loop1:
        mov     esi, dword ptr ds:[eax - 4]
        XOR     esi, dword ptr ds:[eax]
        add     eax, 4
        dec     dword ptr ss:[ebp + 0ch]
        mov     dword ptr ds:[edx + eax - 4], esi
        jnz     @loop1
        mov     edx, dword ptr ss:[ebp - 8h]

@lab2:
        lea     eax, dword ptr ds:[ecx * 4]
        mov     ecx, dword ptr ds:[eax + edi - 4]
        mov     dword ptr ss:[ebp + 0ch], ecx
        jmp     @lab3

@lab6:
        mov     eax, dword ptr ss:[ebp + 0ch]
        mov     dword ptr ss:[ebp + 0ch], eax
        XOR     eax, eax

@lab3:
        test    edx, edx
        je      @lab4
        add     eax, ebx
        XOR     esi, esi
        sub     edi, ebx
        mov     dword ptr ss:[ebp - 8], edx
        mov     edi, edi

@loop2:
        mov     edx, dword ptr ss:[ebp + 0ch]
        mov     ecx, esi
        SHR     edx, cl
        add     esi, 8
        inc     eax
        XOR     dl, byte ptr ds:[edi + eax - 1]
        dec     dword ptr ss:[ebp - 8h]
        mov     byte ptr ds:[eax - 1], dl
        jnz     @loop2
        mov     edi, dword ptr ss:[ebp - 0ch]

@lab4:
        mov     eax, dword ptr ss:[ebp + 8h]
        push    eax
        push    ebx
        push    edi
        call    _memcpy
        add     esp, 0ch
        cmp     byte ptr ss:[ebp - 1], 0
        pop     esi
        je      @lab5
        push    ebx
        call    _free
        add     esp, 4

@lab5:
        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret     8h

@end:
  end;
  setstring(result, pansichar(storedspace), Length(src));
  FreeMem(storedspace);
end;

function TCrypt.returnsize(const what: AnsiString): integer;
var
  ix: integer;
begin
asm
  mov eax, what
  mov ecx, dword [eax]
  mov dword ptr ds:[ix], ecx
end;
  result:=ix+3;
end;

end.
