DTH = "http://www.digitalnc.org/newspapers/daily-tar-heel-chapel-hill-n-c/"
STARTYEAR = 1893
STOPYEAR = 2008
TOOLS = git ant pup
MALLET = ./mallet/bin/mallet
PYTHON = ./venv/bin/python

# machine specs, set in env
MEMORY ?= 12g
CPUS ?= $(shell sysctl hw.ncpu | cut -d ' ' -f 2)

# where to put big intermediate files
SCRATCH ?= .

# check for the make version we need
need := 4.3
ok := $(filter $(need),$(firstword $(sort $(MAKE_VERSION) $(need))))
make_check := $(if $(ok),,\
	$(error Please use GNU make $(need) or later))

.PHONY: \
check_tools \
clean \
superclean \
superduperclean \
confirm

check_tools:
	$(foreach tool,$(TOOLS),\
	$(if $(shell which $(tool)),,\
	$(error Please install $(tool) and ensure it is in your path.)))

# get publication dates of issues in our year range
dates.txt: check_tools
	year=$(STARTYEAR) ; while [[ $$year -le $(STOPYEAR) ]] ; do \
	curl -s $(DTH)?news_year=$$year \
	| pup 'td.active attr{rel}' >> dates.txt ; \
	((year = year + 1)) ; \
	done

# download OCR for all pages
ocr/downloaded: dates.txt
	./download.sh

# install latest development version of MALLET
$(MALLET): check_tools
	git clone https://github.com/mimno/Mallet.git mallet
	cd mallet && ant test
	sed -i -e 's/MEMORY=1g/MEMORY=$(MEMORY)/g' $@

# turn OCR data into a MALLET feature sequence
ocr.sequence: ocr/downloaded | $(MALLET)
	$(MALLET) import-dir \
	--input ocr \
	--keep-sequence \
	--remove-stopwords \
	--output ocr.sequence

# train topic model
models/%-topics.gz: ocr.sequence
	mkdir -p models
	$(MALLET) train-topics \
	--num-threads $(CPUS) \
	--input ocr.sequence \
	--num-topics $* \
	--output-state $@

# $(SCRATCH)/info is for possibly very large intermediate data files...

$(SCRATCH)/info:
	mkdir -p $@

$(SCRATCH)/info/instances.txt: ocr.sequence | $(SCRATCH)/info
	$(MALLET) info \
	--input ocr.sequence \
	--print-instances > $@

$(SCRATCH)/info/features.txt: ocr.sequence | $(SCRATCH)/info
	$(MALLET) info \
	--input ocr.sequence \
	--print-features > $@

$(SCRATCH)/info/feature-counts.tsv: ocr.sequence | $(SCRATCH)/info
	$(MALLET) info \
	--input ocr.sequence \
	--print-feature-counts > $@

$(SCRATCH)/info/%-topics:
	mkdir -p $@

$(SCRATCH)/info/%-topics/topic-word-weights.tsv \
$(SCRATCH)/info/%-topics/doc-topics.tsv \
$(SCRATCH)/info/%-topics/topic-docs.txt &: \
models/%-topics.gz ocr.sequence | $(SCRATCH)/info/%-topics
	$(MALLET) train-topics \
	--num-threads $(CPUS) \
	--input ocr.sequence \
	--num-topics $* \
	--input-state $< \
	--no-inference \
	--topic-word-weights-file $(SCRATCH)/info/$*-topics/topic-word-weights.tsv \
	--output-doc-topics $(SCRATCH)/info/$*-topics/doc-topics.tsv \
	--output-topic-docs $(SCRATCH)/info/$*-topics/topic-docs.txt

# ...end # $(SCRATCH)/info

$(PYTHON):
	python3 -m venv venv
	./venv/bin/pip install --upgrade pip
	./venv/bin/pip install \
	scikit-learn \
	git+https://github.com/rybesh/pyLDAvis.git

viz/%-topics:
	mkdir -p $@

# generate topics visualization
viz/%-topics/index.html: \
$(SCRATCH)/info/instances.txt \
$(SCRATCH)/info/features.txt \
$(SCRATCH)/info/feature-counts.tsv \
$(SCRATCH)/info/%-topics/topic-word-weights.tsv \
$(SCRATCH)/info/%-topics/doc-topics.tsv \
| viz/%-topics $(PYTHON)
	$(PYTHON) viz.py $(SCRATCH)/info $(SCRATCH)/info/$*-topics > $@

# create lists of top documents per topic
viz/%-topics/topdocs.html: \
$(SCRATCH)/info/%-topics/topic-docs.txt \
| viz/%-topics $(PYTHON)
	$(PYTHON) topdocs.py $* $(SCRATCH)/info/$*-topics/topic-docs.txt > $@

clean:
	rm -rf ocr.sequence $(SCRATCH)/info

confirm:
	@/bin/echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

superclean: confirm
	rm -rf dates.txt ocr mallet venv

superduperclean: superclean
	rm -rf models viz

# expensive-to-generate files
.PRECIOUS: \
dates.txt \
ocr.sequence \
models/%-topics.gz \
$(SCRATCH)/info/instances.txt \
$(SCRATCH)/info/features.txt \
$(SCRATCH)/info/feature-counts.tsv \
$(SCRATCH)/info/%-topics/topic-word-weights.tsv \
$(SCRATCH)/info/%-topics/doc-topics.tsv \
$(SCRATCH)/info/%-topics/topic-docs.txt \
viz/%-topics/index.html \
viz/%-topics/topdocs.html
