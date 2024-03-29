import urllib.request
import collections
import datetime
import json
import os
from html.parser import HTMLParser

epoch = datetime.datetime.utcfromtimestamp(0)
START = datetime.date(2019, 4, 3)
START_TIMESTAMP = int(
    (
        datetime.datetime.combine(START, datetime.time.max) - epoch
    ).total_seconds() * 1000 + 1
)
SLACK_API_TOKEN = os.getenv('SLACK_TOKEN')
SLACK_POST_URL = 'https://slack.com/api/chat.postMessage'

Urls = collections.namedtuple('Urls', ('human', 'json'))


class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.strict = False
        self.convert_charrefs = True
        self.fed = []

    def handle_data(self, d):
        self.fed.append(d)

    def get_data(self):
        return ''.join(self.fed)


def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()


def get_urls():
    weeks = int((datetime.date.today() - START).days / 7)
    return Urls(
        (
            'http://www.ljosmodir.is/medgongudagatal?cl=29&'
            f'cd={START_TIMESTAMP}&'
            f'sw={weeks}&sd=0&tw=false'
        ),
        (
            'http://www.ljosmodir.is/Calendar.ashx?action=retrieveWeek&'
            # lol
            f'weekNo={weeks + 1}&twins=false'
        )
    )


def get_info(url):
    req = urllib.request.Request(url)
    response = urllib.request.urlopen(req)
    data = json.loads(response.read().decode('utf8'))
    return strip_tags(data['FullEntry'])


def send_to_slack(*lines):
    entry = {
        'text': '\n'.join(lines),
        # 'channel': 'test',
        'channel': 'general',
    }
    params = json.dumps(entry).encode('utf8')
    req = urllib.request.Request(
        SLACK_POST_URL,
        data=params,
        headers={
            'content-type': 'application/json',
            'Authorization': f'Bearer {SLACK_API_TOKEN}'
        }
    )
    response = urllib.request.urlopen(req)
    data = json.loads(response.read().decode('utf8'))
    print(data)


def handler(event, context):
    urls = get_urls()
    info = get_info(urls.json)
    if SLACK_API_TOKEN:
        send_to_slack(urls.human, info)
    else:
        print('Not sending anything to slack, missing SLACK_API_TOKEN')
        print(urls.human)
        print(info)


if __name__ == '__main__':
    handler(None, None)
