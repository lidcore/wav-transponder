.PHONY: all clean

# Config
SUBDIRS := src
OCAMLFIND := ocamlfind
OCAMLOPT := $(OCAMLFIND) ocamlopt
OCAMLDEP := $(OCAMLFIND) ocamldep
CFLAGS := -fPIC -O3 -Wall -Wextra -I$(shell $(OCAMLOPT) -where) -g
OCAMLFLAGS := -g -ccopt "$(CFLAGS)" $(SUBDIRS:%=-I %)
CC := gcc
x := cmx
i := cmi
V := @

SOURCES := src/riff.ml src/riff.mli src/main.ml

all: wav-transponder

.depend: $(SOURCES)
	$(V)echo OCAMLDEP
	$(V)$(OCAMLDEP) $(SUBDIRS:%=-I %) $(^) > $(@)

%.$(i): %.mli
	$(V)echo OCAMLOPT -c $(<)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -c $(<)

%.$(x): %.ml
	$(V)echo OCAMLOPT -c $(<)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -c $(<)

wav-transponder: $(SOURCES:.ml=.$(x))
	$(V)echo OCAMLOPT -o $(@)
	$(V)$(OCAMLOPT) $(OCAMLFLAGS) -linkpkg -o $(@) $(^)

clean:
	rm -f .depend riff-transponder
	find . -name '*.o' -exec rm \{\} \;
	find . -name '*.cm*' -exec rm \{\} \;

-include .depend
