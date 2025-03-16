#!/usr/bin/env python3

import argparse
from concurrent.futures import ThreadPoolExecutor

from Bio import SeqIO


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Process rvdb fasta description to use taxonomy info when creating a database"
    )
    parser.add_argument("-db", "--input_database", metavar="<path>", help="RVDB database to process", required=True)
    parser.add_argument(
        "-o", "--output_database", metavar="<path>", help="Processed RVDB database", default="RVDB_clustered_db.fasta"
    )
    parser.add_argument("-t", "--threads", type=int, default=4, help="Number of threads to use for parallel processing")

    options = parser.parse_args()
    return options


def process_description(description):
    parts = description.split("|")
    if len(parts) > 4:
        id = parts[2]
        description = parts[-1]
        print(f"{id} {description}")
        return id, description
    return None, None


def process_record(record):
    result = process_description(record.description)
    if result:
        new_id, new_description = result
        record.id = new_id
        record.description = new_description
        return record
    return None


def process_fasta(input_fasta, output_fasta, threads):
    with open(output_fasta, "w") as output_handle, ThreadPoolExecutor(max_workers=threads) as executor:
        for record in SeqIO.parse(input_fasta, "fasta"):
            process = executor.submit(process_record, record)
            processed_record = process.result()
            if processed_record:
                SeqIO.write(processed_record, output_handle, "fasta")


def main():
    options = get_options()
    process_fasta(options.input_database, options.output_database, options.threads)


if __name__ == "__main__":
    main()
