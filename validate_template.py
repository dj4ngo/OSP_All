#!/bin/env python

import json, yaml, sys, datetime
from time import mktime

def myenc(obj):
    if isinstance(obj, datetime.date):
        return obj.__str__()
    else:
        return "dunno"

json.dump(yaml.load(sys.stdin), sys.stdout, indent=2, default=myenc)
