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


PS.
See http://encode.ru/threads/1867-Unrolling-arithmetic-coding
for the thread that started this particular ball rolling.


Usage
-----

The rANS_test.c file builds the rANS_static test application.  This
has -1 and -2 parameters to control 1 and 2 byte (4x8 and 4x16)
renormalisation values, using the code above.  It is also possible to
build rANS_static4c, rANS_static4j and rANS_static64c test executables
with "make old", but these are included only for testing older code
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
/proc/cpuinfo on Ubuntu Trusty).

rANS_static4x8 and rANS_static4x16 refer to the source/algorithm
files, tested by rANS_static -1 and rANS_static -2 executables
respectively.

rANS_static4x16-10 vs rANS_static4x16-9 is a change from 10 to 9 for
the TF_SHIFT_O1 parameter. (The O0 parameter is kept at 12.)
This reduces table lookup size and has a substantial speed improvement
to the decompression times, but at a cost of poorer accuracy in coding
leading to larger files.

Also if cache memory is tight on your CPU, consider switching to the
rans_uncompress_O1c_4x16() function instead of rans_uncompress_O1_sfb_4x16()
or changing ssym[] array to be uint8_t instead of uint16_t in sfb.  (This
will work just fine as 8-bit instead, but seems to be slower on my
system.)

"x" marks deprecated code.

Q40 test file, order 0:

    arith_static            251.2 MB/s enc, 143.0 MB/s dec  94602182 bytes -> 53711390 bytes
    rANS_static4x8          292.6 MB/s enc, 656.3 MB/s dec  94602182 bytes -> 53690159 bytes
    rANS_static4x16         292.7 MB/s enc, 662.6 MB/s dec  94602182 bytes -> 53690572 bytes
  x rANS_static4c           289.2 MB/s enc, 340.0 MB/s dec  94602182 bytes -> 53690171 bytes
  x rANS_static4j           293.7 MB/s enc, 376.1 MB/s dec  94602182 bytes -> 53690159 bytes
    rANS_static64c          279.0 MB/s enc, 439.4 MB/s dec  94602182 bytes -> 53691108 bytes
   
Q8 test file, order 0:

    arith_static            239.1 MB/s enc, 145.4 MB/s dec  73124567 bytes -> 16854053 bytes
    rANS_static4x8          287.5 MB/s enc, 666.2 MB/s dec  73124567 bytes -> 16847597 bytes
    rANS_static4x16         355.9 MB/s enc, 670.1 MB/s dec  73124567 bytes -> 16847762 bytes
  x rANS_static4c           291.7 MB/s enc, 349.5 MB/s dec  73124567 bytes -> 16847633 bytes
  x rANS_static4j           290.5 MB/s enc, 354.2 MB/s dec  73124567 bytes -> 16847597 bytes
    rANS_static64c          351.0 MB/s enc, 549.4 MB/s dec  73124567 bytes -> 16848348 bytes
    
Q40 test file, order 1:

    arith_static            128.4 MB/s enc,  94.7 MB/s dec  94602182 bytes -> 43420823 bytes
    rANS_static4x8          175.3 MB/s enc, 353.5 MB/s dec  94602182 bytes -> 43167683 bytes
    rANS_static4x16-10      199.8 MB/s enc, 401.9 MB/s dec  94602182 bytes -> 43229151 bytes
    rANS_static4x16-9       200.1 MB/s enc, 460.2 MB/s dec  94602182 bytes -> 43415360 bytes
  x rANS_static4c           168.4 MB/s enc, 212.1 MB/s dec  94602182 bytes -> 43167683 bytes
  x rANS_static4j           170.0 MB/s enc, 240.2 MB/s dec  94602182 bytes -> 43167683 bytes
    rANS_static64c          203.9 MB/s enc, 287.1 MB/s dec  94602182 bytes -> 43168614 bytes
    
Q8 test file, order 1:

    arith_static            189.2 MB/s enc, 130.4 MB/s dec  73124567 bytes -> 15860154 bytes
    rANS_static4k-asm       212.3 MB/s enc, 425.3 MB/s dec  73124567 bytes -> 15849814 bytes
    rANS_static4x16-10      246.1 MB/s enc, 504.7 MB/s dec  73124567 bytes -> 15869015 bytes
    rANS_static4x16-9       247.5 MB/s enc, 508.2 MB/s dec  73124567 bytes -> 15892582 bytes
  x rANS_static4c           208.6 MB/s enc, 269.2 MB/s dec  73124567 bytes -> 15849814 bytes
  x rANS_static4j           210.5 MB/s enc, 305.1 MB/s dec  73124567 bytes -> 15849814 bytes
    rANS_static64c          239.2 MB/s enc, 397.6 MB/s dec  73124567 bytes -> 15850522 bytes
