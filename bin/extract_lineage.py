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
    return pytaxonkit.name2taxid(taxon, data_dir=TAXONKIT_DATABASE)["TaxID"].tolist()


def extract_lineage(taxid: str) -> pd.DataFrame:
    lineage = pytaxonkit.lineage(
        taxid,
        formatstr="{k};{K};{p};{c};{o};{f};{g};{s}",
        data_dir=TAXONKIT_DATABASE,
    )
    if pd.isna(lineage["TaxID"].iloc[0]):
        return None

    lineage[LINEAGE_COLUMNS] = lineage["Lineage"].str.split(";", expand=True)
    return lineage[["order", "family", "genus", "species"]]


def main():
    options = get_options()
    taxid = [options.taxon]
    if not taxid[0].isdigit():
        taxid = extract_taxid(taxid)
    lineage_df = extract_lineage(taxid)
    if lineage_df is None:
        print("Homo sapiens\nHomo\nHominidae\nPrimates\n")
        return

    output = lineage_df.melt(value_vars=["species", "genus", "family", "order"], var_name="Category", value_name="Name")
    output["Name"] = output["Name"].replace("", "Indeterminated")
    print(f"{output['Name'].iloc[0]}\n{output['Name'].iloc[1]}\n{output['Name'].iloc[2]}\n{output['Name'].iloc[3]}")


if __name__ == "__main__":
    main()
