.data
afis: .asciz "%d "
afisenter: .asciz "\n"
print_nr_op: .asciz "Operatia nr. %d:\n"
print_debug_all_variables: .asciz "startGetX: %ld\nstartGetY: %ld\nendGetX: %ld\nendGetY: %ld\n"
print_vectori_defrag_string: .asciz "%d: ind: %d, val: %d\n"
print_debug_defrag: .asciz "k: %d, ind: %d, val: %d\n"
print_2d_fara_x: .asciz "((%d, %d), (%d, %d))\n" 
print_2d_cu_x: .asciz "%d: ((%d, %d), (%d, %d))\n"
dbg_print: .asciz "ecx: %d\n"
dbg_print2: .asciz "val: %d\n"
dbg_print3: .asciz "adr_sysmem: %d\n"
citire_1: .asciz "%d"
citire_2: .asciz "%d\n%d"
sysmem: .space 4194340 # 1024 * 1024 * 4
n: .long 1024
n_sqr: .long 1048576
t: .long 0
op: .long 0
nrop: .long 0
valoare: .long 0
size: .long 0

# printget start
last: .long 0
# printgetspecial stop

val_i: .long 0
adr_i: .long 0
adr_ik: .long 0
val_ik: .long 0
# -----addmem START------
addOk: .long 0
blocks: .long 0
count: .long 0
start: .long 0
end: .long 0
k: .long 0
x_addmem: .long 0
nrbytes_addmem: .long 0

addmem_special_startline: .long 0
# ------addmem END-----
aux: .long 0
i: .long 0
# ----- getmem START -----
startGetY: .long 0
startGetX: .long 0
endGetX: .long 0
endGetY: .long 0
okGet: .long 0
x_getmem: .long 0
# ----- getmem END -----
# ------ delmem START
x_delmem: .long 0
# ------ delmem END -----
# ------ defragmem START -----
ind_defrag: .space 2000
val_defrag: .space 2000
k_defrag: .long 0
indice_defrag: .long 0
val_i_defrag: .long 0
adr_inceput_defrag: .long 0
.text

# void print_mem()

print_mem_stupid:
    pushl %ebp
    movl %esp, %ebp
    

    xorl %ecx, %ecx
    print_mem_stupid_loop:
        movl %ecx, %eax
        shl $2, %eax
        addl $sysmem, %eax

        pusha
        pushl (%eax)
        pushl $afis
        call printf
        addl $8, %esp
        popa 

        movl %ecx, %eax
        xorl %edx, %edx
        movl $1024, %ebx
        divl %ebx

        cmpl $0, %edx
        jne print_mem_stupid_loop_afisenter_false
        print_mem_stupid_loop_afisenter:
        pusha
        pushl $afisenter
        call printf
        addl $4, %esp
        popa
        print_mem_stupid_loop_afisenter_false:

        incl %ecx
        cmpl n_sqr, %ecx
        jl print_mem_stupid_loop

    popl %ebp
    ret
print_vectori_defrag:
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx
    print_vectori_defrag_loop:
        pusha

        movl %ecx, %eax
        shl $2, %eax
        addl $val_defrag, %eax
        
        pushl (%eax) # val
        
        movl %ecx, %eax
        shl $2, %eax
        addl $ind_defrag, %eax

        pushl (%eax) # ind

        pushl %ecx # ecx
        pushl $print_vectori_defrag_string
        call printf
        addl $16, %esp

        popa

        incl %ecx
        cmpl k_defrag, %ecx
        jl print_vectori_defrag_loop

    popl %ebp
    ret

print_mem:
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx
    print_mem_loop:
        movl %ecx, %eax
        shl $12, %eax
        addl $sysmem, %eax

        pusha
        pushl %eax
        call print_mem_lin_x
        addl $4, %esp
        popa

        incl %ecx
        cmpl n, %ecx
        jl print_mem_loop
    print_mem_loop_end:

    popl %ebp
    ret


print_mem_lin_x:
    # actualizez baza stivei
    pushl %ebp
    mov %esp, %ebp
    pusha

    xor %ecx, %ecx # i = 0
    mov 8(%ebp), %eax # eax = &sysmem
    loop_print:

print_nr: # printf("%d ", v[i]);
        pusha
        pushl (%eax)
        pushl $afis
        call printf 
        addl $8, %esp
        popa

        addl $4, %eax # x = &v[i + 1]
        incl %ecx # i++;
        cmpl n, %ecx
        jl loop_print
    # printf("\n");
    pushl $afisenter
    call printf
    popl %edx

    pushl $0
    call fflush
    addl $4, %esp

    popa
    popl %ebp
    ret

# Daca nrbytes e > 2048 adauga de nrbytes/2048 ori
# What the actual flying fuck se intampla aici?????
# Si totodata nu se schimba valoarea startGetX si endGetX
# dupa 2048 (/4 cred) trece pe urmatoarea linie wtf?
# si ceva la get e stricat ca ar trebui si get-ul sa fie individual
# pe linii............
add_mem: 
    pushl %ebp
    mov %esp, %ebp
    movl 8(%ebp), %eax
    movl %eax, nrbytes_addmem
    movl 12(%ebp), %eax
    movl %eax, x_addmem
    xorl %ecx, %ecx # i = 0
    movl %ecx, count # count = 0
    movl %ecx, start # start = 0
    movl %ecx, end # end = 0
    movl %ecx, addOk # addOk = 0
    add_mem_loop:
        movl %ecx, %eax
        shl $12, %eax
        addl $sysmem, %eax

        # pusha
        # pushl %ecx
        # pushl $dbg_print
        # call printf
        # addl $8, %esp
        # popa

        pusha
        pushl %eax
        call add_mem_line_x # memmory leak aici, probabil va trebui rescrisa functia ca habar nu am de ce nu merge
        popl %eax
        popa

        # daca addOk = 1 ne oprim
        movl $1, %eax
        cmpl addOk, %eax
        je add_mem_loop_end

        incl %ecx
        cmpl n, %ecx
        jl add_mem_loop
    add_mem_loop_end:
    # afisam
    #  xorl %eax, %eax
    # incl %eax
    # cmpl addOk, %eax
    # jne add_mem_end_frfr
    # afisam doar daca e gasit numarul, adica daca l-am bagat
    pusha
    pushl x_addmem
    call get_mem
    addl $4, %esp
    popa

    pusha
    pushl x_addmem
    call print_get_cu_x
    addl $4, %esp
    popa
    add_mem_end_frfr:
    popl %ebp
    ret

# add_mem_line_x -> push adresa doar
add_mem_line_x:
    pushl %ebp
    mov %esp, %ebp
    # eax = nrbytes / 8
    xorl %ecx, %ecx # i = 0
    movl %ecx, count # count = 0
    movl %ecx, start # start = 0
    movl %ecx, end # end = 0
    movl %ecx, addOk # addOk = 0
    movl %ecx, k # k = 0
    movl nrbytes_addmem, %eax
    cmpl $8, %eax # daca ce tre sa adaugam nu ocupa macar 2 spatii
    jle add_mem_final_line_x # nu adaugam, sarim peste toti pasii
    add_mem_check_already_infile:
        movl x_addmem, %eax
        pusha
        pushl %eax
        call get_mem
        popl %eax
        popa
        movl okGet, %eax
        cmpl $1, %eax
        je add_mem_final_line_x
    add_mem_check_already_infile_end:
    mov nrbytes_addmem, %eax
    xor %edx, %edx
    mov $8, %ebx
    divl %ebx
    # daca edx != 0 incrementam eax si eax va fi egal cu blocks
    cmpl $0, %edx
    je not_add1_blocks_line_x
    incl %eax
    not_add1_blocks_line_x:
    movl %eax, blocks
    # am setat corect valoarea lui blocks
    xorl %eax, %eax # eax = 0
    xor %ecx, %ecx # ecx = i = 0
    add_mem_firstloop_line_x:
        # v[i] = $(addmem) + 4 * ecx
        movl %ecx, i
        movl %ecx, %eax
        shl $2, %eax
        # eax = 4 * i
        addl 8(%ebp), %eax
        # eax = &v[i] -> (%eax) = v[i]
        movl (%eax), %ebx # transportam valoarea pt ca nu putem folosi 2 valori in memorie
        movl %ebx, val_i # val_i = v[i]
        movl %eax, adr_i # adr_i = &v[i]
        add_mem_first_if_line_x:
        cmpl $0, %ebx
        jne add_mem_first_else_line_x
        # count++
        movl count, %eax
        incl %eax
        movl %eax, count
        jmp add_mem_first_if_end_line_x
        add_mem_first_else_line_x:
        xorl %eax, %eax
        movl %eax, count
        add_mem_first_if_end_line_x:
        # second if
        add_mem_second_if_line_x:
        movl count, %eax
        cmpl %eax, blocks
        jne add_mem_second_if_end_line_x
        # nu ne mai trebuie i de la ecx pt ca iesim oricum din functie dupa
        xorl %ecx, %ecx # k = 0
            add_mem_second_if_loop_line_x:

            
            

            # adr_i - 4 * ecx = adresa corespunzatoare
            movl %ecx, %eax
            shl $2, %eax
            # eax = 4 * ecx
            movl adr_i, %ebx
            subl %eax, %ebx
            movl %ebx, %eax
            # eax = adr_v[i-k]
            movl %eax, adr_ik
            # eax = v[i - k]
            movl x_addmem, %edx
            movl %edx, (%eax) # pune numarul
            # for loop

            subl $sysmem, %eax
            shr $2, %eax
            # pusha
            # pushl %eax
            # pushl $dbg_print2
            # call printf
            # addl $8, %esp
            # popa

            incl %ecx
            cmpl blocks, %ecx
            jl add_mem_second_if_loop_line_x
        # am terminat de pus valorile
        xorl %eax, %eax
        incl %eax
        addl i, %eax
        subl blocks, %eax
        movl %eax, start

        movl i, %eax
        movl %eax, end

        movl $1, %eax
        movl %eax, addOk

        # pushl 
        # pushl $dbg_print2
        # call printf
        # addl $8, %esp

        jmp add_mem_final_line_x
        add_mem_second_if_end_line_x:
        incl %ecx
        cmpl n, %ecx
        jl add_mem_firstloop_line_x
    add_mem_final_line_x:
    popl %ebp
    ret

get_mem: # vrea x
    pushl %ebp
    mov %esp, %ebp

    movl 8(%ebp), %eax
    movl %eax, x_getmem

    xorl %ecx, %ecx # i = 0
    movl %ecx, startGetX
    movl %ecx, endGetX
    get_mem_loop:
        movl %ecx, %eax # eax = i
        shl $12, %eax # eax = 1024*i = urmatoarea adresa de block
        addl $sysmem, %eax # eax = adresa de inceput de la linia i
    
        pusha # just in case
        pushl %eax # adr_linie
        call get_mem_line_x
        addl $4, %esp
        popa # just in case
        
        # call print_everything_debug
        # acum verificam variabilele de la get si in functie de asta
        # continuam sau nu
        # daca nu e okGet trecem mai departe
        # daca e ok trebuie sa afisam si linia i (adica pe %ecx)
        xorl %eax, %eax 
        cmpl okGet, %eax # actualizat de get_mem_line_x
        je get_mem_gasit_end # 0 != 1
        # daca nu, mergem mai departe
        get_mem_gasit:
            # ecx-ul nostru este x-ul, sunt identice ca tre sa fie pe aceeasi linie
            movl %ecx, startGetX
            movl %ecx, endGetX
            jmp get_mem_loop_end
        get_mem_gasit_end:
    
        incl %ecx
        cmpl n, %ecx
        jl get_mem_loop
    get_mem_loop_end:

    popl %ebp
    ret

# vrea push x si dupa push adresa
get_mem_line_x: # de pe linia care incepe la adresa x... pana n block-uri mai incolo, la finalul liniei
    pushl %ebp
    mov %esp, %ebp

    xorl %ecx, %ecx # i = 0
    movl %ecx, startGetY # startGet = 0
    movl %ecx, endGetY # endGet = 0
    movl %ecx, okGet # okGet = 0
    get_mem_line_x_loop:
    # v[i] = ecx * 4 + &sysmem
    movl %ecx, %eax # eax = i
    shl $2, %eax # eax = 4 * i
    et_debug3:
    addl 8(%ebp), %eax # eax = &v[i]
    movl (%eax), %ebx # ebx = v[i]
    movl %ebx, val_i # val_i = v[i]
    movl %eax, %ebx
    movl %ebx, adr_i
    movl x_getmem, %eax # eax = x
    cmpl %eax, val_i # v[i] vs val[i]
    jne get_mem_line_x_loop_first_if_end 
    # aici intram in if
    movl %ecx, startGetY # startget = i, face corect pana aici!!
    # -----UPDATE LA COD MEMMORY SAFE!!------
    pushl %eax
    xorl %eax, %eax
    incl %eax
    movl %eax, okGet
    popl %eax

    get_mem_line_x_loop_first_while:
        movl %ecx, %eax # eax = i
        shl $2, %eax # eax = 4 * i
        
        addl 8(%ebp), %eax # eax = &v[i]
        movl (%eax), %ebx # ebx = v[i]
        movl %ebx, val_i # val_i = v[i]
        et_debug:
        movl x_getmem, %eax # eax = x
        cmpl %eax, val_i # x vs v[i]
        jne get_mem_line_x_loop_first_while_end
        cmpl %ecx, n # n vs i
        je get_mem_line_x_loop_first_while_end
        # conditii suficiente sa facem loop cu i++
        incl %ecx # i ++
        jmp get_mem_line_x_loop_first_while
    get_mem_line_x_loop_first_while_end:
    decl %ecx # i--
    movl %ecx, endGetY # endGet = i
    jmp get_mem_line_x_loop_end
    get_mem_line_x_loop_first_if_end:
    incl %ecx # i++
    cmpl %ecx, n # i vs n
    jne get_mem_line_x_loop
    get_mem_line_x_loop_end:

    popl %ebp
    ret



print_get:
    pushl %ebp
    mov %esp, %ebp

    pusha

    pushl endGetY
    pushl endGetX
    pushl startGetY
    pushl startGetX
    pushl $print_2d_fara_x
    call printf
    addl $20, %esp

    popa

    popl %ebp
    ret


delete_mem:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl %eax, x_delmem # x_delmem = x de sters

    xorl %ecx, %ecx # ecx = 0
    delete_mem_loop:
        movl %ecx, %eax
        shl $2, %eax
        addl $sysmem, %eax
        movl (%eax), %ebx
        cmpl x_delmem, %ebx
        jne delete_mem_if_end
        delete_mem_if:
            movl $0, (%eax)
        delete_mem_if_end:

        incl %ecx
        cmpl n_sqr, %ecx
        jl delete_mem_loop
    delete_mem_loop_end:
    # printGetSpecial 
    # call print_mem # DEBUG 
    et_debug4:
    # call print_get_special

    popl %ebp
    ret

delete_everything:
    pushl %ebp
    movl %esp, %ebp
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    delete_everything_loop:
        movl %ecx, %eax
        shl $2, %eax
        addl $sysmem, %eax
        movl %ebx, (%eax) # v[i] = 0

        incl %ecx
        cmpl n_sqr, %ecx
        jl delete_everything_loop
    popl %ebp
    ret

add_mem_startline_x:
    pushl %ebp
    mov %esp, %ebp
    movl 8(%ebp), %eax
    movl %eax, nrbytes_addmem
    movl 12(%ebp), %eax
    movl %eax, x_addmem
    xorl %ecx, %ecx # i = 0
    movl %ecx, count # count = 0
    movl %ecx, start # start = 0
    movl %ecx, end # end = 0
    movl %ecx, addOk # addOk = 0
    movl indice_defrag, %ecx # incepem de pe linia coresp.
    add_mem_loop_startline_x:
        movl %ecx, %eax
        shl $12, %eax
        addl $sysmem, %eax

        # pusha
        # pushl %ecx
        # pushl $dbg_print
        # call printf
        # addl $8, %esp
        # popa

        pusha
        pushl %eax
        call add_mem_line_x # memmory leak aici, probabil va trebui rescrisa functia ca habar nu am de ce nu merge
        popl %eax
        popa

        # daca addOk = 1 ne oprim
        movl $1, %eax
        cmpl addOk, %eax
        je add_mem_loop_end_startline_x

        incl %ecx
        cmpl n, %ecx
        jl add_mem_loop_startline_x
    add_mem_loop_end_startline_x:
    popl %ebp
    ret


defrag_mem:
    # tinem minte 3 vectori
    # ind[i] = indicele nr i
    # val[i] = cati de i
    # indice_defrag - unde am adaugat ultima oara, ca sa adaugam obligatoriu incepand de pe aceeasi linie
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx
    movl %ecx, indice_defrag # indice_defrag = 0
    movl %ecx, k_defrag # k_defrag = 0
    # initializam si vectorii cu 0, deci facem for
    xorl %eax, %eax
    xorl %ebx, %ebx
    defrag_mem_init_vect_zero_loop:
        movl %ecx, %eax
        shl $2, %eax
        addl $val_defrag, %eax
        movl %ebx, (%eax)

        movl %ecx, %eax
        shl $2, %eax
        addl $ind_defrag, %eax
        movl %ebx, (%eax)

        incl %ecx
        cmpl $256, %ecx
        jl defrag_mem_init_vect_zero_loop
    defrag_mem_init_vect_zero_loop_end:

    xorl %ecx, %ecx
    defrag_mem_first_loop:
        movl %ecx, %eax
        shl $12, %eax
        addl $sysmem, %eax
        movl %eax, adr_inceput_defrag
        pushl %ecx # salvam ecx
        xorl %ecx, %ecx
        defrag_mem_second_loop:
        # aparent daca sunt 2 valori pe acelasi rand sare peste whatt??
            movl %ecx, %eax
            shl $2, %eax
            addl adr_inceput_defrag, %eax
            movl (%eax), %ebx
            movl %ebx, val_i_defrag # pastram valoarea pt mai tarziu in caz de orice
            cmpl $0, %ebx
            je defrag_mem_second_loop_first_if_end
            defrag_mem_second_loop_first_if:
            # am gasit, deci dam get
            pusha
            pushl %ebx
            call get_mem
            addl $4, %esp
            popa 

            movl endGetY, %ecx # optimizare

            movl startGetY, %eax
            movl endGetY, %ebx
            subl %eax, %ebx
            incl %ebx

            movl k_defrag, %eax
            shl $2, %eax
            addl $val_defrag, %eax
            movl %ebx, (%eax) # salvat in vectorul val

            # pusha
            # pushl %ebx # print val

            movl k_defrag, %eax
            shl $2, %eax
            addl $ind_defrag, %eax
            movl val_i_defrag, %ebx
            movl %ebx, (%eax) # salvat valoarea in vectorul ind

            # pushl %ebx # print ind
            # pushl k_defrag # print k
            # pushl $print_debug_defrag
            # call printf
            # addl $16, %esp
            # popa

            # incrementam pe k dupa
            movl k_defrag, %eax
            incl %eax
            movl %eax, k_defrag

            # dam delete la ce am gasit ca sa nu facem de 10 ori sa iasa din memorie
            # pushl val_i_defrag
            # call delete_mem
            # addl $4, %esp

            defrag_mem_second_loop_first_if_end:
            # daca v[i] != 0 dam get, salvam datele de la get in vectori
            # si dupa dam delete de v[i]
            incl %ecx
            cmpl n, %ecx
            jl defrag_mem_second_loop
        defrag_mem_second_loop_end:
        popl %ecx # restauram ecx
        incl %ecx
        cmpl n, %ecx
        jl defrag_mem_first_loop
    defrag_mem_first_loop_end:
    pusha
    # call print_vectori_defrag
    call delete_everything # facem tot 0
    popa
    
    xorl %ecx, %ecx
    movl %ecx, indice_defrag # indice_defrag = ultima linie pe care am adaugat, trebuie sa adaugam tot acolo
    defrag_mem_3rd_loop:
        pusha
        # pushl indice_defrag

        movl %ecx, %eax
        shl $2, %eax
        addl $ind_defrag, %eax
        pushl (%eax)
        # trebuie inmultit cu 8 mai intai
        

        movl %ecx, %eax
        shl $2, %eax
        addl $val_defrag, %eax
        movl (%eax), %ebx
        movl %ebx, %eax
        shl $3, %eax
        pushl %eax # prima valoare pentru apelul de add

        call add_mem_startline_x
        addl $8, %esp
        popa
        # actualizam indicele de defragmentare
        # cautam valoarea si vedem linia la care a fost pusa
        pusha
        movl %ecx, %eax
        shl $2, %eax
        addl $ind_defrag, %eax
        pushl (%eax)
        call get_mem
        addl $4, %esp
        popa
        # puteam recicla dar asta este, nu risc
        movl startGetX, %eax 
        movl %eax, indice_defrag

        incl %ecx
        cmpl k_defrag, %ecx
        jl defrag_mem_3rd_loop
    # defragmentarea propriu-zisa
    # for de la 1 la k (exclusiv)
    # pentru a pastra indicele corect actualizam la fiecare pas care a fost ultima linie unde am adaugat, si adaugam obligatoriu de acolo in jos
    # deci: add(ind[i], val[i])
    # vedem pe ce linie a adaugat si tinem minte nr acela, dandu-l ca parametru la add-ul de data viitoare, deci se actualizeaza intr-un fel singur

    call print_get_special # posibil sa nu avem nevoie de asta din cauza la add-urile repetate
    popl %ebp
    ret

print_get_special:
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx # i = 0
    print_get_special_loop:
        movl %ecx, %eax
        shl $12, %eax
        addl $sysmem, %eax

        pusha
        pushl %eax
        call print_get_special_line_x
        popl %eax
        popa

        incl %ecx
        cmpl n, %ecx
        jl print_get_special_loop
    print_get_special_loop_end:
    popl %ebp
    ret

print_get_special_line_x: # pushl adr_inceput_linie
    pushl %ebp
    movl %esp, %ebp
    xorl %ecx, %ecx # i = 0
    movl %ecx, last
    print_get_special_line_x_loop:
    cmpl n, %ecx
    jge print_get_special_line_x_loop_end
    # inside for
    # primul if
    movl %ecx, %eax
    shl $2, %eax # eax *= 4
    addl 8(%ebp), %eax # eax = &(v[i])
    movl (%eax), %ebx
    cmpl last, %ebx
    je print_get_special_line_x_if_end
    cmpl $0, %ebx
    je print_get_special_line_x_if_end
    print_get_special_line_x_if:
    # am intrat in if
        pusha
        pushl %ebx
        call get_mem
        popl %ebx

        pushl %ebx
        call print_get_cu_x
        popl %ebx
        popa
        movl %ebx, last # last = v[i]        
    print_get_special_line_x_if_end:
    incl %ecx
    jmp print_get_special_line_x_loop
    print_get_special_line_x_loop_end:
    popl %ebp
    ret

print_get_cu_x: # pushl x
    pushl %ebp
    mov %esp, %ebp

    pusha    
    pushl endGetY
    pushl endGetX
    pushl startGetY
    pushl startGetX
    pushl 8(%ebp) # x
    pushl $print_2d_cu_x
    call printf
    addl $24, %esp

    popa
    popl %ebp
    ret

print_everything_debug:
    pushl %ebp
    movl %esp, %ebp
    # "startGetX: %d\nstartGetY: %d\nendGetX: %d\nendGetY: %d\n"
    pusha
    pushl endGetY
    pushl endGetX
    pushl startGetY
    pushl startGetX
    pushl $print_debug_all_variables
    call printf
    addl $20, %esp
    popa

    popl %ebp
    ret

.global main
main:
    # pusha
    # pushl $sysmem
    # pushl $dbg_print3
    # call printf
    # addl $8, %esp
    # popa

    pushl $t
    pushl $citire_1
    call scanf
    addl $8, %esp
    main_loop:
        # secveta pt afisat cate operatii mai sunt (asta e, e descrescator)
        # pusha   
        # pushl t
        # pushl $print_nr_op
        # call printf
        # addl $8, %esp
        # popa

        pushl $op
        pushl $citire_1
        call scanf
        addl $8, %esp
        switch_op:
        movl op, %eax
        cmpl $1, %eax
        je case_0
        cmpl $2, %eax
        je case_1
        cmpl $3, %eax
        je case_2
        cmpl $4, %eax
        je case_3
        case_0:
        # op == 1
        pushl $nrop
        pushl $citire_1
        call scanf
        addl $8, %esp
        xorl %ecx, %ecx # i = 0
        main_loop_first_op_loop:
            pusha
            pushl $valoare
            pushl $size
            pushl $citire_2
            call scanf
            addl $12, %esp
            popa

            pusha
            pushl size
            pushl valoare
            call add_mem
            addl $8, %esp
            popa

            et_debug2:
            incl %ecx
            cmpl %ecx, nrop
            jne main_loop_first_op_loop
        # la final de add afisam tot!
        # APARENT NU MAI AFISAM LA FINAL DE ADD TOT!
        # call print_get_special
        jmp switch_op_end
        case_1:
        pushl $valoare
        pushl $citire_1
        call scanf
        addl $8, %esp

        pushl valoare
        call get_mem
        addl $4, %esp

        call print_get

        jmp switch_op_end
        case_2:
        pushl $valoare
        pushl $citire_1
        call scanf
        addl $8, %esp

        pushl valoare
        call delete_mem
        addl $4, %esp

        call print_get_special

        jmp switch_op_end
        case_3:
        # TO BE DONE
        call defrag_mem 
        jmp switch_op_end
        switch_op_end:
        # call print_get_special
        # call print_mem # DEBUG misto :)
        # call print_mem_stupid
        # call print_everything_debug
        movl t, %eax
        decl %eax
        movl %eax, t
        cmpl $0, %eax
        jne main_loop
    main_loop_end:
    pushl $0
    call fflush
    addl $4, %esp
et_exit: 
    mov $1, %eax
    xor %ebx, %ebx
    int $0x80
