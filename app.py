#!/usr/bin/env python

import time

from flask import Flask

app = Flask(__name__)
global sleepy_time = 1


@app.route("/health")
def health():
    time.sleep(sleepy_time)
    return {"sleep": sleepy_time }


@app.route("/sleep/<amount>", methods=["POST", "PUT"])
def sleep(amount):
    sleepy_time = amount
    return {"sleep": sleepy_time }


if __name__ == "__main__":
    app.run()
