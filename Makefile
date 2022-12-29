PANDOC = pandoc 
PANDOCOPTIONS = -c css/style.css -f markdown -s --katex=katex/ -t html5

MD=$(subst README.md,,$(wildcard *.md))
HTML = $(MD:.md=.html)

%.html: %.md
	${PANDOC} ${PANDOCOPTIONS} -o $@ $^

all: ${HTML}

clean: 
	rm -f $(HTML)


