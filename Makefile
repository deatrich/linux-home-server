#***************************************************************************
# $Id$
#
# Purpose: makefile for doc. --> generate html and pdf files from an md file
#
#***************************************************************************

#***************************************************************************
.SUFFIXES : .md .html .pdf
#.SILENT :

#***************************************************************************
## get object file names from source file names

PROJECT		= linux-server
FILELIST	= contents.txt
GENDIR		= "Generated/"
PUBDIR		= "../deatrich.github.io/linux-home-server/current/"
MDFILE		= $(PROJECT).md
MDFILES		= $(shell cat ${FILELIST})
HTMLOBJECT	= $(MDFILE:.md=.html)
PDFOBJECT	= $(MDFILE:.md=.pdf)
PDFVIEWER	= evince
HTMLVIEWER	= firefox

#***************************************************************************
PRINTOPT	= 
PANDOC_OPTS	= --toc --toc-depth=3 --syntax-definition=console.xml \
		 --highlight-style=custom-highlight.theme
PANDOC_HTML_OPTS = -c https://deatrich.github.io/style.css --template template.htm \
		 -V lastupdate="`date +'%d %B %Y'`"
PANDOC_PDF_OPTS	= --template=template.latex -V geometry:margin=2cm \
		 --pdf-engine=xelatex

#***************************************************************************
## DEFAULT GOAL

all:	$(HTMLOBJECT) $(PDFOBJECT)

test:
	echo "$(MDFILES)"

#***************************************************************************
## DEPENDENCIES

$(PDFOBJECT): $(MDFILES) template.latex console.xml custom-highlight.theme

$(HTMLOBJECT): $(MDFILES) template.htm console.xml custom-highlight.theme \
       	style.css

#***************************************************************************
## GENERAL RULES

html: $(HTMLOBJECT)

pdf: $(PDFOBJECT)

showhtml: $(HTMLOBJECT)
	$(HTMLVIEWER) $(HTMLOBJECT)

showpdf: $(PDFOBJECT)
	$(PDFVIEWER) $(PDFOBJECT)

copies: $(PDFOBJECT) $(HTMLOBJECT)
	cp -up $(PDFOBJECT) $(GENDIR)$(PDFOBJECT) 
	cp -up $(HTMLOBJECT) $(GENDIR)$(HTMLOBJECT) 

publish: $(PDFOBJECT) $(HTMLOBJECT)
	cp -iup $(PDFOBJECT) $(PUBDIR)$(PDFOBJECT) 
	cp -iup $(HTMLOBJECT) $(PUBDIR)$(HTMLOBJECT) 

help:	
	@echo ""
	@echo "make all          -- update all file types"
	@echo "make html         -- update the html file"
	@echo "make pdf          -- update the pdf file"
	@echo "make showhtml     -- show the html file"
	@echo "make showpdf      -- show the pdf file"
	@echo "make copies       -- push html and pdf copies to generated area"
	@echo "make publish      -- push html and pdf copies to web site"
	@echo "make clean        -- clean up generated files"

.md.html :
	pandoc -s $(MDFILES) $(PANDOC_OPTS) $(PANDOC_HTML_OPTS) -o $(HTMLOBJECT)

.md.pdf :
	pandoc -s $(MDFILES) $(PANDOC_OPTS) $(PANDOC_PDF_OPTS) -o $(PDFOBJECT)

## manually clean up generated files from time to time
clean:
	-rm -i *.html *.pdf

