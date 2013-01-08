COFFEE = ./node_modules/.bin/coffee
WATCH = $(COFFEE) ./tools/watch.coffee

LIBDIR = lib
SRCDIR = src
vpath %.coffee $(SRCDIR)

SRC = $(wildcard $(SRCDIR)/*.coffee)
LIB = $(patsubst $(SRCDIR)/%.coffee,$(LIBDIR)/%.js,$(SRC))

.SUFFIXES: .coffee .js
.PHONY: all build watch clean

all: build
build: $(LIB)

$(LIB): | $(LIBDIR)

$(LIBDIR):
	@mkdir -p "$@"

$(LIBDIR)/%.js: %.coffee
	$(COFFEE) -j < "$<" > "$@"

clean:
	@rm -r $(LIBDIR)

watch:
	$(WATCH) $(LIBDIR) $(SRCDIR)
