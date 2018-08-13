#! /usr/bin/env python3

import sys

BASE_URL = 'http://newspapers.digitalnc.org/lccn/sn92073228/'
DOCS = 10

header = '''<!doctype html>
<meta charset=utf-8><title>top documents per topic</title>
<body style="max-width: 800px">
<h1>Top ten documents per topic</h1>'''


def link(f):
    d = f.split('/')[6:9]
    return ('<a href="%s" style="text-decoration: none">%s, page %s</a>'
            % (BASE_URL + '/'.join(d) + '/', d[0], d[2].split('-')[1]))


print(header)

print('Topics: ')
for topic_num in range(1, int(sys.argv[1]) + 1):
    print('<a href="#%s" style="text-decoration: none">%s</a>'
          % (topic_num, topic_num))

with open(sys.argv[2]) as f:
    next(f)
    last_topic = None
    count = 0
    for line in f:
        topic, doc, filename, proportion = line.split()[0:4]
        if topic == last_topic:
            count += 1
        else:
            if last_topic is not None:
                print('</table>')
            topic_num = int(topic) + 1
            print('<h2 id="%s">Topic %s</h2>' % (topic_num, topic_num))
            print('<table>')
            last_topic = topic
            count = 1
        if count > DOCS:
            continue
        print('<tr><td>%s</td><td>%s</td></tr>' % (proportion, link(filename)))
    if last_topic is not None:
        print('</table>')
