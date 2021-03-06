from subprocess import PIPE
import subprocess

from termcolor import colored

from src.common import get_collections_data

if __name__ == '__main__':
    collections = get_collections_data()['collections']
    for collection in collections:
        call = ['docker-compose', 'run', '--rm', 'snoop--' + collection, './manage.py',
                'updatename', collection.lower(), collection]
        print(call, end='', flush=True)
        process = subprocess.run(call, stdout=PIPE, stderr=PIPE)
        if process.returncode == 0:
            print(colored(' [SUCCESS]', 'green'))
        else:
            print(colored(' [ERROR]', 'red'))
            print(process.stderr.decode('ASCII'))
            print(process.stdout.decode('ASCII'))
