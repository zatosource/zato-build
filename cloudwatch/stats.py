# -*- coding: utf-8 -*-
from zato.server.service import Service


class Stats(Service):
    class SimpleIO:
        output_required = ('value')

    def handle(self):
        self.response.payload.value = 123
