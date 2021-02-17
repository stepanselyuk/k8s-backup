import json
import os
import sys
import yaml

def parse_bundle():

    if sys.argv[1] is None:
        print("Please provide the bundle file path.")
        exit(1)

    input_filepath = sys.argv[1]
    basedir = os.path.dirname(input_filepath)

    if "_cluster.json" in input_filepath:
        basedir = os.path.join(basedir, "_cluster")

    with open(input_filepath, 'r') as file:

        data = json.load(file)
        prev_kind = None
        created_list = []

        item: dict
        for item in data["items"]:

            print("%s -> %s [%s]" % (item["kind"], item["metadata"]["name"], item["metadata"]["creationTimestamp"]))

            if prev_kind is None:
                created_list = []
            elif prev_kind != item["kind"]:
                created_list.sort(reverse=True)
                target_dir = os.path.join(basedir, prev_kind)
                with open(os.path.join(target_dir, "_created.txt"), 'w') as file_output:
                    for created_str in created_list:
                        file_output.write('%s\n' % created_str)
                created_list = []

            prev_kind = item["kind"]
            created_list.append("%s\t%s" % (item["metadata"]["creationTimestamp"], item["metadata"]["name"]))

            # write json file (full)

            subpath = "%s/_json" % item["kind"]
            target_dir = os.path.join(basedir, subpath)

            if not os.path.isdir(target_dir):
                os.makedirs(target_dir)

            output_filepath = os.path.join(target_dir, "%s.json" % item["metadata"]["name"])

            with open(output_filepath, 'w') as file_output:
                json.dump(item, file_output, indent=2)

            # write yaml file (some keys deleted)

            item.pop("status", None)
            item["metadata"].pop("uid", None)
            item["metadata"].pop("ownerReferences", None)
            item["metadata"].pop("generateName", None)
            item["metadata"].pop("selfLink", None)
            item["metadata"].pop("resourceVersion", None)
            item["metadata"].pop("creationTimestamp", None)
            item["metadata"].pop("generation", None)

            if "annotations" in item["metadata"]:
                item["metadata"]["annotations"].pop("deployment.kubernetes.io/revision", None)
                item["metadata"]["annotations"].pop("kubectl.kubernetes.io/last-applied-configuration", None)

            target_dir = os.path.join(basedir, item["kind"])
            output_filepath = os.path.join(target_dir, "%s.yaml" % item["metadata"]["name"])

            with open(output_filepath, 'w') as file_output:
                yaml.dump(item, file_output)

            # print(item)
            #
            # break


if __name__ == '__main__':
    parse_bundle()
