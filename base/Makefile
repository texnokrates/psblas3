include ../Make.inc

HERE=.
LIBDIR=../lib
INCDIR=../include
MODDIR=../modules
LIBNAME=$(BASELIBNAME)

lib: mods sr cm in pb tl
	/bin/cp -p $(CPUPDFLAG) $(HERE)/$(LIBNAME) $(LIBDIR)
	/bin/cp -p $(CPUPDFLAG) *$(.mod) $(MODDIR)

sr cm in pb tl: mods

mods:
	cd modules && $(MAKE) lib LIBNAME=$(BASELIBNAME) F90="$(MPF90)" F90COPT="$(F90COPT) $(MPI_OPT)"
sr:
	cd serial && $(MAKE) lib LIBNAME=$(BASELIBNAME)
cm:
	cd comm && $(MAKE) lib LIBNAME=$(BASELIBNAME)
in:
	cd internals && $(MAKE) lib LIBNAME=$(BASELIBNAME)
pb:
	cd psblas && $(MAKE) lib LIBNAME=$(BASELIBNAME)
tl:
	cd tools && $(MAKE) lib LIBNAME=$(BASELIBNAME)

clean: 
	(cd modules; $(MAKE) clean)
	(cd comm; $(MAKE) clean)
	(cd internals; $(MAKE) clean)
	(cd tools; $(MAKE) clean)
	(cd serial; $(MAKE) clean)
	(cd psblas; $(MAKE) clean)

veryclean: clean 
	/bin/rm -f $(HERE)/$(LIBNAME) $(LIBMOD) *$(.mod)
