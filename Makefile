#***************************************************************************
# $Id$
#
# Purpose: makefile for doc. --> generate html and pdf files from an md file
#
#***************************************************************************


#***************************************************************************

TARG	= linux-server.md

.SUFFIXES : .md .html .pdf

#.SILENT :

#***************************************************************************
## get object file names from source file names

MDFILE		= $(TARG)
HTMLOBJECT	= $(MDFILE:.md=.html)
PDFOBJECT	= $(MDFILE:.md=.pdf)
PDFVIEWER	= evince
HTMLVIEWER	= firefox


#***************************************************************************
PRINTOPT	= 
PANDOC_OPTS	= -c style.css --toc --toc-depth=3 --syntax-definition=shell.xml
PANDOC_HTML_OPTS = --template template.htm
PANDOC_PDF_OPTS	= --template=template.latex --highlight-style=custom-highlight.theme -V geometry:margin=2cm --pdf-engine=xelatex

#***************************************************************************
## GENERAL RULES

all:	$(HTMLOBJECT) $(PDFOBJECT)

pdf:	$(PDFOBJECT) template.latex shell.xml custom-highlight.theme style.css
	$(MAKE) $(PDFOBJECT)

html:	$(HTMLOBJECT) template.htm shell.xml style.css
	$(MAKE) $(HTMLOBJECT)

showhtml: $(HTMLOBJECT)
	$(HTMLVIEWER) $(HTMLOBJECT)

showpdf: $(PDFOBJECT)
	$(PDFVIEWER) $(PDFOBJECT)

help:	
	@echo ""
	@echo "make all          -- update all file types"
	@echo "make html         -- update the html file"
	@echo "make pdf          -- update the pdf file"
	@echo "make showhtml     -- show the html file"
	@echo "make showpdf      -- show the pdf file"
	@echo "make clean        -- clean up generated files"

.md.html :
	pandoc -s $< $(PANDOC_OPTS) $(PANDOC_HTML_OPTS) -o $(HTMLOBJECT)

.md.pdf :
	pandoc -s $< $(PANDOC_OPTS) $(PANDOC_PDF_OPTS) -o $(PDFOBJECT)

## manually clean up generated files from time to time
clean:
	-rm -i *.html *.pdf

