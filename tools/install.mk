COFFEE = ./node_modules/.bin/coffee

LIBDIR = lib
SRCDIR = src
vpath %.coffee $(SRCDIR)

SRC = $(wildcard $(SRCDIR)/*.coffee)
LIB = $(patsubst $(SRCDIR)/%.coffee,$(LIBDIR)/%.js,$(SRC))

.SUFFIXES: .coffee .js
.PHONY: all clean

all: $(LIB)

$(LIB): | $(LIBDIR)

$(LIBDIR):
	@mkdir -p "$@"

$(LIBDIR)/%.js: %.coffee
	$(COFFEE) -j < "$<" > "$@"

clean:
	$(RM) -r $(LIBDIR)
