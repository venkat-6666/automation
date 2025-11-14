import time
import socket
import os
import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)

def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)

@app.route('/')
def hello():
    count = get_hit_count()
    container_id = socket.gethostname()
    container_ip = socket.gethostbyname(container_id)
    node_hostname = os.getenv('NODE_HOSTNAME', 'unknown')
    
    return (
        f'Hello World! I have been seen {count} times.\n'
        f'Container ID: {container_id}\n'
        f'Container IP: {container_ip}\n'
        f'Docker Node: {node_hostname}\n'
        f'Redis Hits: {count}\n'
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0')
