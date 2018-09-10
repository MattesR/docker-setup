import argparse
import json

from src.common import get_collections_data


def get_args():
    parser = argparse.ArgumentParser(description='List collections.')
    parser.add_argument('-j', '--json', action='store_const', const=True, default=False,
                        help='Output in json format.')
    return parser.parse_args()


def print_collections(collections):
    index = 1
    for collection, settings in collections.items():
        print('%d. %s' % (index, collection))
        print('  - profiling: %s' % settings['profiling'])
        print('  - development: %s' % settings['for_dev'])
        print('  - auto-indexing: %s' % settings['autoindex'])
        index += 1


def list_collections(args):
    collections, _, _, _ = get_collections_data()
    if args.json:
        print(json.dumps(collections, indent=4))
    else:
        print_collections(collections)
