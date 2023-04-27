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

TARG		= linux-server.md
GENDIR		= "generated/"
MDFILE		= $(TARG)
HTMLOBJECT	= $(MDFILE:.md=.html)
PDFOBJECT	= $(MDFILE:.md=.pdf)
PDFVIEWER	= evince
HTMLVIEWER	= firefox

#***************************************************************************
PRINTOPT	= 
PANDOC_OPTS	= -c style.css --toc --toc-depth=3 --syntax-definition=shell.xml --highlight-style=custom-highlight.theme
PANDOC_HTML_OPTS = --template template.htm
PANDOC_PDF_OPTS	= --template=template.latex -V geometry:margin=2cm --pdf-engine=xelatex

#***************************************************************************
## DEFAULT GOAL

all:	$(HTMLOBJECT) $(PDFOBJECT)

#***************************************************************************
## DEPENDENCIES

$(PDFOBJECT): $(MDFILE) template.latex shell.xml custom-highlight.theme

$(HTMLOBJECT): $(MDFILE) template.htm shell.xml custom-highlight.theme style.css

#***************************************************************************
## GENERAL RULES

showhtml: $(HTMLOBJECT)
	$(HTMLVIEWER) $(HTMLOBJECT)

showpdf: $(PDFOBJECT)
	$(PDFVIEWER) $(PDFOBJECT)

copies: $(PDFOBJECT) $(HTMLOBJECT)
	cp -p $(PDFOBJECT) $(GENDIR)$(PDFOBJECT) 
	cp -p $(HTMLOBJECT) $(GENDIR)$(HTMLOBJECT) 

help:	
	@echo ""
	@echo "make all          -- update all file types"
	@echo "make html         -- update the html file"
	@echo "make pdf          -- update the pdf file"
	@echo "make showhtml     -- show the html file"
	@echo "make showpdf      -- show the pdf file"
	@echo "make copies       -- push html and pdf copies to generated area"
	@echo "make clean        -- clean up generated files"

.md.html :
	pandoc -s $< $(PANDOC_OPTS) $(PANDOC_HTML_OPTS) -o $(HTMLOBJECT)

.md.pdf :
	pandoc -s $< $(PANDOC_OPTS) $(PANDOC_PDF_OPTS) -o $(PDFOBJECT)

## manually clean up generated files from time to time
clean:
	-rm -i *.html *.pdf

