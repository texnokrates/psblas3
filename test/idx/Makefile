INSTALLDIR=../..
INCDIR=$(INSTALLDIR)/include
MODDIR=$(INSTALLDIR)/modules/
include $(INCDIR)/Make.inc.psblas
#
# Libraries used
LIBDIR=$(INSTALLDIR)/lib
PSBLAS_LIB= -L$(LIBDIR) -lpsb_util -lpsb_krylov -lpsb_prec -lpsb_base 
LDLIBS=$(PSBLDLIBS)
#
# Compilers and such
#
CCOPT= -g
FINCLUDES=$(FMFLAG)$(MODDIR) $(FMFLAG).


EXEDIR=./runs

all: tryidxijk psb_d_pde3d test_gf731

tryidxijk: tryidxijk.o 
	$(FLINK)  tryidxijk.o -o tryidxijk $(PSBLAS_LIB) $(LDLIBS)
	/bin/mv tryidxijk $(EXEDIR)

psb_d_pde3d: psb_d_pde3d.o 
	$(FLINK)  psb_d_pde3d.o -o psb_d_pde3d $(PSBLAS_LIB) $(LDLIBS)
	/bin/mv psb_d_pde3d $(EXEDIR)
test_gf731: test_gf731.o 
	$(FLINK)  test_gf731.o -o test_gf731 $(PSBLAS_LIB) $(LDLIBS)
	/bin/mv test_gf731 $(EXEDIR)



clean: 
	/bin/rm -f tryidxijk.o test_gf731.o psb_d_pde3d.o *$(.mod) \
	$(EXEDIR)/tryidxijk $(EXEDIR)/psb_d_pde3d
verycleanlib: 
	(cd ../..; make veryclean)
lib:
	(cd ../../; make library)



