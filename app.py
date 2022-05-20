#!/usr/bin/env python

import time

from flask import Flask

app = Flask(__name__)
app.sleepy_time = 1


@app.route("/health")
def health():
    time.sleep(app.sleepy_time)
    return {"sleep": app.sleepy_time }


@app.route("/sleep/<amount>", methods=["POST", "PUT"])
def sleep(amount):
    app.sleepy_time = int(amount)
    return {"sleep": app.sleepy_time }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
