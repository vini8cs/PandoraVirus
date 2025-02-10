#!/usr/bin/env python3
import argparse
import os

import pandas as pd
import pytaxonkit

TAXONKIT_DATABASE = os.getenv("TAXONKIT_DATABASE")

LINEAGE_COLUMNS = ["kingdom", "superkingdom", "phylum", "class", "order", "family", "genus", "species"]


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract taxon lineage")
    parser.add_argument("-t", "--taxon", metavar="<text>", help="Taxon name", required=True)
    parser.add_argument(
        "-o", "--output", metavar="<path>", help="output file with lineage info", default="lineage_info.txt"
    )

    options = parser.parse_args()

    return options


def extract_taxid(taxon: str) -> list:
    return pytaxonkit.name2taxid([taxon], data_dir=TAXONKIT_DATABASE)["TaxID"].tolist()


def extract_lineage(taxid: str) -> pd.DataFrame:
    lineage = pytaxonkit.lineage(
        taxid,
        formatstr="{k};{K};{p};{c};{o};{f};{g};{s}",
        data_dir=TAXONKIT_DATABASE,
    )
    lineage[LINEAGE_COLUMNS] = lineage["Lineage"].str.split(";", expand=True)
    return lineage[["order", "family", "genus", "species"]]


def main():
    options = get_options()
    taxid = extract_taxid(options.taxon)
    lineage_df = extract_lineage(taxid)
    output = lineage_df.melt(
        value_vars=["species", "genus", "family", "order"], var_name="Category", value_name="Name"
    )["Name"]
    output.to_csv(options.output, sep="\t", index=False, header=False)


if __name__ == "__main__":
    main()
