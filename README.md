## Requirements

* [make](https://www.gnu.org/software/make/)
* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [ant](https://ant.apache.org/manual/install.html)
* [pup](https://github.com/EricChiang/pup#install)

`make` comes standard on Unix systems including MacOS; on Windows it will need to be installed. The other programs will need to be installed according to the instructions linked above.


## Usage

Clone this repository:
```
git clone git@github.com:rybesh/dth-topics.git
```

All commands must be run from the `dth-topics` directory:
```
cd dth-topics
```

To download OCR data for newspaper pages from the Digital NC Daily Tar Heel archive:
```
make ocr
```

To install [MALLET](http://mallet.cs.umass.edu) and use it to train topic models on the OCR data:
```
make models
```

To create visualizations of the topic models:
```
make viz
```

To view the visualizations for the _n_-topics model (e.g. 10-topics, 100-topics), open `viz/`_n_`-topics/viz.html`.

To create lists of the top (most closely associated) documents for each topic:
```
make top
```

To view the top documents per topic for the _n_-topics model (e.g. 10-topics, 100-topics), open `viz/`_n_`-topics/topdocs.html`.
