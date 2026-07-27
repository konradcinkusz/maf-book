.PHONY: all watch clean shots

all:
	latexmk -pdf -interaction=nonstopmode main.tex

watch:
	latexmk -pvc -pdf -interaction=nonstopmode main.tex

clean:
	latexmk -C
	rm -f *.shots *.ilg *.ind *.idx

# List every screenshot the book is still waiting on
shots:
	@grep -rn '\\needscreenshot{' chapters appendices frontmatter \
	  | sed -E 's/.*needscreenshot\{([^}]*)\}.*/\1/' \
	  | sort -u \
	  | while read k; do \
	      [ -f "figures/screenshots/$$k.png" ] || echo "MISSING: $$k.png"; \
	    done
