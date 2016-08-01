CFLAGS=-O3 -g -mtune=native -Wall

PROGS=arith_static rANS_static
all: $(PROGS)

OLD_PROGS=rANS_static4c rANS_static4j rANS_static64c
old: $(OLD_PROGS)

.c.o:
	$(CC) $(CFLAGS) $(DEFINES) -c $<

arith_static: DEFINES+=-DTEST_MAIN
arith_static: arith_static.o
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

rANS_static4c: DEFINES+=-DTEST_MAIN
rANS_static4c: rANS_static4c.o
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

rANS_static4j: DEFINES+=-DTEST_MAIN
rANS_static4j: rANS_static4j.o
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

rANS_static64c: DEFINES+=-DTEST_MAIN
rANS_static64c: rANS_static64c.o
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

# rANS_static4x8: DEFINES+=-DTEST_MAIN
# rANS_static4x8: rANS_static4x8.o
# 	$(CC) $(CFLAGS) -o $@ $< $(LIBS)
# 
# rANS_static4x16: DEFINES+=-DTEST_MAIN
# rANS_static4x16: rANS_static4x16.o
# 	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

OBJ=rANS_static.o rANS_static4x8.o rANS_static4x16.o rANS_test.o
rANS_static: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ) $(LIBS)

clean:
	-rm *.o
	-rm $(PROGS) $(OLD_PROGS)
