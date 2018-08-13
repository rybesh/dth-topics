import sys
import csv
import os.path
import pyLDAvis
import numpy as np


def normalize(weights):
    s = sum(weights)
    return [w/s for w in weights]


def load_topic_term_dists(filename):
    dists = []
    with open(filename) as f:
        reader = csv.reader(f, delimiter="\t")
        topic = weights = None
        for row in reader:
            if not row[0] == topic:
                if weights is not None:
                    dists.append(normalize(weights))
                topic = row[0]
                weights = []
            weights.append(float(row[2]))
            topic = row[0]
        if weights is not None:
            dists.append(normalize(weights))
    return dists


def load_doc_topic_dists(filename):
    dists = []
    with open(filename) as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            dists.append([float(x) for x in row[2:]])
    return dists


def load_doc_lengths(filename):
    lengths = []
    with open(filename) as f:
        length = None
        for line in f:
            if len(line.strip()) == 0:
                continue
            if line.startswith('file:'):
                if length is not None:
                    lengths.append(length)
                length = 1
            else:
                length = int(line.split(':')[0])
        if length is not None:
            lengths.append(length)
    return lengths


def load_vocab(filename):
    vocab = []
    with open(filename) as f:
        for line in f:
            vocab.append(line.strip())
    return vocab


def load_term_frequency(filename):
    counts = []
    with open(filename) as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            counts.append(int(row[1]))
    return counts


def load_mallet_model(path):
    return {
        'topic_term_dists':
        load_topic_term_dists(os.path.join(path, 'topic-word-weights.tsv')),
        'doc_topic_dists':
        load_doc_topic_dists(os.path.join(path, 'doc-topics.tsv')),
        'doc_lengths':
        load_doc_lengths(os.path.join(path, 'instances.txt')),
        'vocab':
        load_vocab(os.path.join(path, 'features.txt')),
        'term_frequency':
        load_term_frequency(os.path.join(path, 'feature-counts.tsv')),
        'sort_topics':
        False
    }


path = sys.argv[1]
model = load_mallet_model(path)

print('Topic-term shape: %s' % str(np.array(model['topic_term_dists']).shape))
print('Doc-topic shape: %s' % str(np.array(model['doc_topic_dists']).shape))
print('Doc lengths shape: %s' % str(np.array(model['doc_lengths']).shape))

pyLDAvis.save_html(
    pyLDAvis.prepare(**model),
    os.path.join(path, 'viz.html'))
