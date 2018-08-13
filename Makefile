DTH = "http://www.digitalnc.org/newspapers/daily-tar-heel-chapel-hill-n-c/"
YEARS = 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989
TOPIC_COUNTS = 10 50 100
CORES := $(shell sysctl hw.ncpu | cut -d ' ' -f 2)
TOOLS = git ant pup

# check for the tools we need
X := $(foreach tool,$(TOOLS),\
	$(if $(shell which $(tool)),,\
	$(error "Please install $(tool) and ensure it is in your path")))

# install latest development version of MALLET
mallet/class:
	git clone git@github.com:mimno/Mallet.git mallet
	rm -rf mallet/src/cc/mallet/pipe/tests # broken tests won't compile
	cd mallet && ant

# get publication dates of issues in our year range
dates.txt:
	$(foreach year,$(YEARS),\
	curl -s "$(DTH)?news_year=$(year)" \
	| pup 'td.active attr{rel}' >> dates.txt \
	;)

# download OCR for all pages
ocr: dates.txt
	./download.sh

# turn OCR data into a MALLET feature sequence
ocr.sequence: ocr mallet/class
	./mallet/bin/mallet import-dir \
	--input ocr \
	--keep-sequence \
	--remove-stopwords \
	--output ocr.sequence

# train topic models
models: ocr.sequence
	mkdir models
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet train-topics \
	--num-threads $(CORES) \
	--input ocr.sequence \
	--num-topics $(k) \
	--output-state models/$(k)-topics.gz \
	;)

# create virtualenv and install pyLDAvis
venv:
	virtualenv -p python3 venv
	./venv/bin/pip install pyldavis

# create visualizations and summaries
viz: models venv
	mkdir viz
	$(foreach k,$(TOPIC_COUNTS),mkdir viz/$(k)-topics;)
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet info \
	--input ocr.sequence \
	--print-instances > viz/$(k)-topics/instances.txt \
	;)
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet info \
	--input ocr.sequence \
	--print-features > viz/$(k)-topics/features.txt \
	;)
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet info \
	--input ocr.sequence \
	--print-feature-counts > viz/$(k)-topics/feature-counts.tsv \
	;)
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet train-topics \
	--num-threads $(CORES) \
	--input ocr.sequence \
	--num-topics $(k) \
	--input-state models/$(k)-topics.gz \
	--no-inference \
	--topic-word-weights-file viz/$(k)-topics/topic-word-weights.tsv \
	--output-doc-topics viz/$(k)-topics/doc-topics.tsv \
	--output-topic-docs viz/$(k)-topics/topic-docs.txt \
	;)
	$(foreach k,$(TOPIC_COUNTS),./venv/bin/python3 viz.py viz/$(k)-topics;)

# create lists of top documents per topic
top:
	$(foreach k,$(TOPIC_COUNTS),\
	./mallet/bin/mallet train-topics \
	--num-threads $(CORES) \
	--input ocr.sequence \
	--num-topics $(k) \
	--input-state models/$(k)-topics.gz \
	--no-inference \
	--output-topic-docs viz/$(k)-topics/topic-docs.txt \
	;)
	$(foreach k,$(TOPIC_COUNTS),\
	./venv/bin/python3 topdocs.py $(k) \
	viz/$(k)-topics/topic-docs.txt > viz/$(k)-topics/topdocs.html \
	;)


clean:
	rm -f ocr.sequence

superclean: clean
	rm -rf mallet dates.txt ocr

.PHONY: clean superclean
