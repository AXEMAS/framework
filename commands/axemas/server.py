from __future__ import print_function

from gearbox.command import Command
from SimpleHTTPServer import SimpleHTTPRequestHandler
import BaseHTTPServer
import os
import webbrowser
import threading
import time


class ServeProjectCommand(Command):
    def get_description(self):
        return 'Runs an HTTP Server which can be used to test AXEMAS Apps from a Browser'

    def get_parser(self, prog_name):
        parser = super(ServeProjectCommand, self).get_parser(prog_name)
        return parser

    def take_action(self, opts):
        if not os.path.exists('www'):
            print('Not inside an AXEMAS project, the WWW directory should be here!')
            return False

        httpd = BaseHTTPServer.HTTPServer(('', 8000), CORSRequestHandler)
        sa = httpd.socket.getsockname()
        url = 'http://{}:{}/www'.format(*sa)
        root_url = '{}/sections/index/index.html'.format(url)

        print("Serving on {}... default Root Section is {}".format(url, root_url))
        OpenBrowserThread(root_url).start()
        httpd.serve_forever()


class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        SimpleHTTPRequestHandler.end_headers(self)


class OpenBrowserThread(threading.Thread):
    def __init__(self, url):
        super(OpenBrowserThread, self).__init__(target=self.open_browser,
                                                kwargs={'url': url})
        self.daemon = True

    def open_browser(self, url):
        time.sleep(1.0)
        webbrowser.open_new_tab(url)