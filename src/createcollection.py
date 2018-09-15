import argparse
from collections import OrderedDict
import os.path

from jinja2 import Template

from src.common import get_collections_data, validate_collections, cleanup, \
    write_global_docker_file, templates_dir_name, collection_allowed_chars, \
    validate_collection_name, validate_collection_data_dir, create_settings_dir, \
    write_collection_docker_file, volumes_dir_name, write_python_settings_file, \
    default_snoop_image, write_env_file

steps_file_name = 'collection-%s-steps.txt'


def write_instructions(args):
    with open(os.path.join(templates_dir_name, 'collection-steps.txt')) as steps_template:
        template = Template(steps_template.read())
        steps = template.render(collection_name=args.collection,
                                collection_index=str.lower(args.collection))

    collection_steps_file_name = steps_file_name % '%s' % args.collection
    with open(collection_steps_file_name, mode='w') as steps_file:
        steps_file.write(steps)

    print(open(collection_steps_file_name).read())
    print('\nThe steps above are described in "%s"' % collection_steps_file_name)


def get_args():
    parser = argparse.ArgumentParser(description='Create a collection.')
    parser.add_argument('-c', '--collection', required=True,
                        help='Collection name; allowed characters: ' + collection_allowed_chars)
    parser.add_argument('-s', '--snoop-image', default=default_snoop_image,
                        help='Snoop docker image')
    parser.add_argument('-d', '--dev', action='store_const', const=True, default=False,
                        help='Add development settings to the docker file')
    parser.add_argument('-p', '--profiling', action='store_const', const=True, default=False,
                        help='Add profiling settings for the new collection.')
    parser.add_argument('-m', '--manual-indexing', action='store_const', const=True, default=False,
                        help='Do not add the option to start indexing automatically.')
    args = parser.parse_args()

    validate_collection_name(args.collection)

    return args


def create_pg_dir(collection):
    pg_dir = os.path.join(volumes_dir_name, 'snoop-pg--%s' % collection)
    if not os.path.isdir(pg_dir):
        os.mkdir(pg_dir)


def create_collection(args):
    collections, snoop_port, pg_port, dev_instances = get_collections_data(args.collection)
    if len(collections):
        validate_collections(collections)
    validate_collection_data_dir(args.collection)

    try:
        create_pg_dir(args.collection)
        settings_dir = create_settings_dir(args.collection)

        collections[args.collection] = {'profiling': args.profiling, 'for_dev': args.dev}
        ordered_collections = OrderedDict(sorted(collections.items(), key=lambda t: t[0]))

        write_collection_docker_file(args.collection, args.snoop_image, settings_dir,
                                     snoop_port, args.profiling, args.dev, pg_port,
                                     not args.manual_indexing)
        write_env_file(settings_dir)
        write_python_settings_file(args.collection, settings_dir, args.profiling, args.dev)
        write_global_docker_file(ordered_collections, args.dev or bool(dev_instances))
    except Exception as e:
        print('Error creating collection: %s' % e)
        cleanup(args.collection)
        raise

    write_instructions(args)
