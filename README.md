Introduction
------------

These are my derivations of Fabien 'Ryg's rANS coder plus a
static arithmetic coder derived from Eugene Shelwein's work.
Therefore none of the really complex stuff is my own and the real
credit belongs elsewhere.

The originals can be found at:
-    https://github.com/rygorous/ryg_rans
-    http://ctxmodel.net (defunct?)

I thought about forking this, but I didn't do that way back when I
first created my variants and so it'd be a fork in name only, with no
actual history.

The arithmetic coder was designed to be a fast unrolled variant that
coded using multiple arithmetic coders simultaneously. I also
implemented a static order-1 model in addition to the usual order-0.

About the same time I'd finished that code the ANS implementations
started arriving so I took Ryg's original rANS (two way interleaved
variant) and produced a 4-way interleaved version.  Successive
optimisations lead version "4c".  Most recently I explored some newer
tweaks and ideas.

- arith_static.c
	The unrolled order-0/1 arithmetic coder.

- rANS_static4x8.c
	A 4-way unrolled order-0/1 rANS coder with 8-bit renormalisation.
	This is compatible with the rANS_static4c (and 4j) variants
	used in CRAM, but more heavily optimised with additional
	assembly.

- rANS_static4x16.c
	A variant of the rANS_static4 code that uses 16-bit
	renormalisation.  It is incompatible with the 4x8 output.
	This is the same idea used in Ryg's SIMD variant; by keeping
	the rANS state as 15+16 instead of 23+8 we only ever have one
	normalisation step instead of two.  This also uses assembly.

	Note that to further test the maximum performance of order-1
	encoding, the table sizes were reduced to 9 bits for 4x16
	instead of 12 bits used in order-0 (and 12 in both order-0 and
	order-1 in 4x8).  Thus the two are not directly comparable
	with the order-1 method.

- rANS_static64c.c, rans64.h
	A 4 way unrolled version of Ryg's rans64.h.
	(This needs a mulhi cpu instruction to do 64-bit by 64-bit
	multiplication and take the top 64-bits of the result.
	Available on most(all?) x86_64 architectures, but I needed to
	consider 32-bit hosts too.)

There are also some more experimental codecs for investigating use of
SIMD (in a rather poor state code-wise at present with lots of
warnings and commented out bits of code).  On some of these the
order-1 coder is non functioning or not yet updated.

- rNx16.c
	A generic N-way interleaving with N states and N decode/encode
	buffers.  This is an attempt to permit automatic vectorisation
	within compilers by removing dependency between the loop over
	N states, but it suffers from a large amount of memory
	gathers.  Compile with eg -DNX=32 to change N.
	NB: at present only icc seems able to vectorise the decoder.

- rNx16b.c
	A generic N-way interleaving with N states and one shared
	decode/encode buffer.  This has better memory utilisation than
	rNx16.c, but the shared buffer makes automatic vectorisation
	challenging.
	With -DNX=4 this is binary compatible with rANS_static4x16.c
	output. but around 10-20% slower to due no manual reordering
	of the statements.

- r8x16_sse.c
- r8x16_avx2.c
- r16x16_avx2.c
- r16x16_avx512.c
- r32x16_avx2.c
- r32x16_avx512.c
	Various custom versions of rNx16.c using SSE, AVX2 or AVX512
	instructions for N 8, 16 and 32.

- r8x16b_avx2.c
- r16x16b_avx2.c
- r16x16b_avx512.c
- r32x16b_avx2.c
- r32x16b_avx512.c
	Various custom versions of rNx16b.c using SSE, AVX2 or AVX512
	instructions for N 8, 16 and 32.
	These are typically faster than the rNx16.c variants.


PS.
See http://encode.ru/threads/1867-Unrolling-arithmetic-coding
for the thread that started this particular ball rolling.


Usage
-----

The rANS_test.c file builds the rANS_static test application.  This
has -8 and -16 parameters to control 8 and 16 bit renormalisation
values, using the code above.  It is also possible to build
rANS_static4c, rANS_static4j and rANS_static64c test executables with
"make old", but these are included only for testing older code
variants.

Order 0 encoding and decoding

    rANS_static -o0 in in.rans0
    rANS_static -d in.rans0 in.decoded

Order 1 encoding and decoding

    rANS_static -o0 in in.rans1
    rANS_static -d in.rans1 in.decoded

Testing/benchmarking order 1

    rANS_static -o1 -t in


Benchmarks
----------

Q40 and Q8 are DNA sequencing quality values with approx 40 and 8
distinct values each, representing high and low complexity data.

    $ head -5 /tmp/Q40
    AAA7DDFFFHHHGFHIGHGIGGIJIGHCIGGHBGFCGGGEGGCGEG@F;FC;8@@F>@E@6)=?B66?@A;?(555;=((,55(((((+2(39(288<
    :?A=DA;?BDH?F<BGG>F>?;EF>8:8?E>FHGIIIEIHICH9@F(?BFEEGHEIIC<@DEEEEEC2?=A;;?@?;((5,5?9(9<0()9388(>AC
    AAA@ABFFFHHHGHGJIGEEIGHIGIIIIIJIHEGIGGIGGGIDGIIIJH>B<@DD;;B?E===;@FDGH3=@EAHA;?))7;6((.5(,;(,((5(,
    ?BABFABDFHHHHHHHIJJJJJIIJJJGHGIJDIE@DDGDF@GHGGGAEGGCEE>CDFDB;>>A@=;AC??BBDC(<A<?C<AB?<??AB8<(28?09
    2((2+&)&)&(+24++(((+22(:))&&0-))&&&)&3,,,((,,'',''-(/)).))))(((((0(()))3.--2))).))2)50-(((((((((((
    
 $ head -5 /tmp/Q8
    --A--JJ7-----<---7-
    7----<--<<-<7-7--FF
    --FAAA7-JFFFF<FFJ<7<FFFJFAJFFFJJAAF<A<JJ<FJJ7FJJFFJJ7F7FAAJJFFFFJJJJFJFJJFJFJFJJJJFJFJJFFJF<JJFJJJJJ7FJJJJF<7<FJJJAJJJFAFJFFFJF<JFJJJJJJFAJJFJJJJJFFFFF
    JJJ<JJJJ<JJJJJ7FFJFJJFJJF<AFAAJJJFJFJJ7FJFJJ7FFJJFJFFFFF<<AAFJJAFF
    FFFFFJFJJFJJJFJJJJJAJJJJAJJJFJJJJFJJJJFJJJJJJJJJJJJJJJFJFJFAJJJJJJJFJAJJJJ<AJJJJJJFJJJJFFJFJFJJFFJFJJFFJFJJAJJJJFJJ7JJJJAJJJ7J-FAJAJ7JJJAFFAFFFAFF-JFFA


Tested on an "Intel(R) Core(TM) i5-4570 CPU @ 3.20GHz" (from
/proc/cpuinfo on Ubuntu Trusty) using Intel icc-15 compiler.

Also if cache memory is tight on your CPU, consider switching to the
rans_uncompress_O1c_4x16() function instead of rans_uncompress_O1_sfb_4x16()
or changing ssym[] array to be uint8_t instead of uint16_t in sfb.  (This
will work just fine as 8-bit instead, but seems to be slower on my
system.)

icc-15 Q8 test file, order 0:

    arith_static        244.6 MB/s enc, 166.2 MB/s dec	 73124567 bytes -> 16854053 bytes
    rANS_static4x8      300.8 MB/s enc, 657.6 MB/s dec	 73124567 bytes -> 16847496 bytes
    rANS_static4x16     366.4 MB/s enc, 637.4 MB/s dec	 73124567 bytes -> 16847764 bytes
    rANS_static4c       294.6 MB/s enc, 317.7 MB/s dec	 73124567 bytes -> 16847633 bytes
    rANS_static4j       298.8 MB/s enc, 347.5 MB/s dec	 73124567 bytes -> 16847597 bytes
    rANS_static64c      417.2 MB/s enc, 517.1 MB/s dec	 73124567 bytes -> 16848348 bytes
    r4x16               336.4 MB/s enc, 370.7 MB/s dec	 73124567 bytes -> 16848884 bytes
    r8x16               339.7 MB/s enc, 540.6 MB/s dec	 73124567 bytes -> 16850828 bytes
    r16x16              340.3 MB/s enc, 648.3 MB/s dec	 73124567 bytes -> 16854740 bytes
    r32x16              298.3 MB/s enc, 636.7 MB/s dec	 73124567 bytes -> 16862640 bytes
    r4x16b              336.6 MB/s enc, 432.2 MB/s dec	 73124567 bytes -> 16847764 bytes
    r8x16b              339.7 MB/s enc, 433.7 MB/s dec	 73124567 bytes -> 16848588 bytes
    r16x16b             342.0 MB/s enc, 433.8 MB/s dec	 73124567 bytes -> 16850260 bytes
    r32x16b             301.8 MB/s enc, 410.9 MB/s dec	 73124567 bytes -> 16853680 bytes
    r8x16_sse           332.6 MB/s enc, 563.8 MB/s dec	 73124567 bytes -> 16850828 bytes
    r8x16_avx2          341.1 MB/s enc, 582.9 MB/s dec	 73124567 bytes -> 16850828 bytes
    r16x16_avx2         339.8 MB/s enc, 971.1 MB/s dec	 73124567 bytes -> 16854740 bytes
    r32x16_avx2         293.5 MB/s enc, 891.8 MB/s dec	 73124567 bytes -> 16862640 bytes
    r8x16b_avx2         346.2 MB/s enc, 583.4 MB/s dec	 73124567 bytes -> 16848588 bytes
    r16x16b_avx2        347.4 MB/s enc, 972.1 MB/s dec	 73124567 bytes -> 16850260 bytes
    r32x16b_avx2        470.3 MB/s enc, 1343.2 MB/s dec	 73124567 bytes -> 16853680 bytes

icc-15 Q40 test file, order 0:

    arith_static        265.9 MB/s enc, 168.5 MB/s dec	 94602182 bytes -> 53711390 bytes
    rANS_static4x8      318.3 MB/s enc, 650.0 MB/s dec	 94602182 bytes -> 53687617 bytes
    rANS_static4x16     297.6 MB/s enc, 630.7 MB/s dec	 94602182 bytes -> 53688461 bytes
    rANS_static4c       295.2 MB/s enc, 336.8 MB/s dec	 94602182 bytes -> 53690171 bytes
    rANS_static4j       301.3 MB/s enc, 357.6 MB/s dec	 94602182 bytes -> 53690159 bytes
    rANS_static64c      318.6 MB/s enc, 410.1 MB/s dec	 94602182 bytes -> 53691108 bytes
    r4x16               277.6 MB/s enc, 371.0 MB/s dec	 94602182 bytes -> 53689917 bytes
    r8x16               232.6 MB/s enc, 541.0 MB/s dec	 94602182 bytes -> 53692425 bytes
    r16x16              226.2 MB/s enc, 638.3 MB/s dec	 94602182 bytes -> 53697503 bytes
    r32x16              207.7 MB/s enc, 598.2 MB/s dec	 94602182 bytes -> 53707709 bytes
    r4x16b              271.4 MB/s enc, 429.8 MB/s dec	 94602182 bytes -> 53688461 bytes
    r8x16b              230.8 MB/s enc, 432.1 MB/s dec	 94602182 bytes -> 53689513 bytes
    r16x16b             228.2 MB/s enc, 432.7 MB/s dec	 94602182 bytes -> 53691679 bytes
    r32x16b             210.6 MB/s enc, 411.1 MB/s dec	 94602182 bytes -> 53696061 bytes
    r8x16_sse           234.1 MB/s enc, 566.7 MB/s dec	 94602182 bytes -> 53692425 bytes
    r8x16_avx2          230.0 MB/s enc, 576.2 MB/s dec	 94602182 bytes -> 53692425 bytes
    r16x16_avx2         224.8 MB/s enc, 961.0 MB/s dec	 94602182 bytes -> 53697503 bytes
    r32x16_avx2         203.6 MB/s enc, 764.9 MB/s dec	 94602182 bytes -> 53707709 bytes
    r8x16b_avx2         236.5 MB/s enc, 582.2 MB/s dec	 94602182 bytes -> 53689513 bytes
    r16x16b_avx2        229.3 MB/s enc, 962.2 MB/s dec	 94602182 bytes -> 53691679 bytes
    r32x16b_avx2        462.8 MB/s enc, 1330.4 MB/s dec	 94602182 bytes -> 53696061 bytes

icc-15 Q40 test file, order 1:

    arith_static        186.2 MB/s enc, 132.7 MB/s dec	 73124567 bytes -> 15860154 bytes
    rANS_static4x8      189.6 MB/s enc, 363.2 MB/s dec	 73124567 bytes -> 15849814 bytes
    rANS_static4x16     221.8 MB/s enc, 406.1 MB/s dec	 73124567 bytes -> 15866984 bytes
    rANS_static4c       183.3 MB/s enc, 267.4 MB/s dec	 73124567 bytes -> 15849814 bytes
    rANS_static4j       192.3 MB/s enc, 298.1 MB/s dec	 73124567 bytes -> 15849814 bytes
    rANS_static64c      230.3 MB/s enc, 385.0 MB/s dec	 73124567 bytes -> 15850522 bytes
    r4x16               not supported
    r8x16               not supported
    r16x16              not supported
    r32x16              not supported
    r4x16b              233.9 MB/s enc, 286.2 MB/s dec	 73124567 bytes -> 15866984 bytes
    r8x16b              164.6 MB/s enc, 288.9 MB/s dec	 73124567 bytes -> 15867863 bytes
    r16x16b             147.5 MB/s enc, 291.5 MB/s dec	 73124567 bytes -> 15869665 bytes
    r32x16b             125.0 MB/s enc, 285.4 MB/s dec	 73124567 bytes -> 15873242 bytes
    r8x16_sse           not supported
    r8x16_avx2          not supported
    r16x16_avx2         not supported
    r32x16_avx2         not supported
    r8x16b_avx2         not supported
    r16x16b_avx2        not supported
    r32x16b_avx2        212.5 MB/s enc, 918.1 MB/s dec	 73124567 bytes -> 15873242 bytes

icc-15 q40 test file, order 1:

    arith_static        130.0 mb/s enc, 101.0 mb/s dec	 94602182 bytes -> 43420823 bytes
    rans_static4x8      147.9 mb/s enc, 324.0 mb/s dec	 94602182 bytes -> 43167683 bytes
    rans_static4x16     171.1 mb/s enc, 396.9 mb/s dec	 94602182 bytes -> 43383241 bytes
    rans_static4c       144.9 mb/s enc, 203.9 mb/s dec	 94602182 bytes -> 43167683 bytes
    rans_static4j       150.2 mb/s enc, 239.0 mb/s dec	 94602182 bytes -> 43167683 bytes
    rans_static64c      192.5 mb/s enc, 292.0 mb/s dec	 94602182 bytes -> 43168614 bytes
    r4x16               not supported
    r8x16               not supported
    r16x16              not supported
    r32x16              not supported
    r4x16b              181.6 mb/s enc, 259.5 mb/s dec	 94602182 bytes -> 43383241 bytes
    r8x16b              130.8 mb/s enc, 261.6 mb/s dec	 94602182 bytes -> 43384646 bytes
    r16x16b             120.4 mb/s enc, 262.8 mb/s dec	 94602182 bytes -> 43387506 bytes
    r32x16b             107.3 mb/s enc, 261.6 mb/s dec	 94602182 bytes -> 43392566 bytes
    r8x16_sse           not supported
    r8x16_avx2          not supported
    r16x16_avx2         not supported
    r32x16_avx2         not supported
    r8x16b_avx2         not supported
    r16x16b_avx2        not supported
    r32x16b_avx2        206.8 MB/s enc, 813.7 MB/s dec	 94602182 bytes -> 43392566 bytes


gcc-4.8 tests on r32x16b_avx2:

    q8  order 0         408.2 MB/s enc, 1305.2 MB/s dec  73124567 bytes -> 16853680 bytes
    q40 order 0         403.9 MB/s enc, 1294.9 MB/s dec  94602182 bytes -> 53696061 bytes
    q8  order 1         205.7 MB/s enc, 840.0 MB/s dec   73124567 bytes -> 15873242 bytes
    q40 order 1         200.4 MB/s enc, 724.0 MB/s dec   94602182 bytes -> 43392566 bytes

gcc-5.3 tests on r32x16b_avx2:

    q8  order 0         515.5 MB/s enc, 1450.9 MB/s dec  73124567 bytes -> 16853680 bytes
    q40 order 0         513.7 MB/s enc, 1439.4 MB/s dec  94602182 bytes -> 53696061 bytes
    q8  order 1         212.0 MB/s enc, 879.0 MB/s dec   73124567 bytes -> 15873242 bytes
    q40 order 1         206.2 MB/s enc, 755.3 MB/s dec   94602182 bytes -> 43392566 bytes

gcc-6.1 tests on r32x16b_avx2:

    q8  order 0         511.2 MB/s enc, 1432.7 MB/s dec  73124567 bytes -> 16853680 bytes
    q40 order 0         503.5 MB/s enc, 1417.6 MB/s dec  94602182 bytes -> 53696061 bytes
    q8  order 1         217.1 MB/s enc, 910.4 MB/s dec   73124567 bytes -> 15873242 bytes
    q40 order 1         211.7 MB/s enc, 783.1 MB/s dec   94602182 bytes -> 43392566 bytes
