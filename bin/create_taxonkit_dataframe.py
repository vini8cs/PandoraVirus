#!/usr/bin/env python3

import argparse
import os

import pandas as pd
import pytaxonkit
from pandarallel import pandarallel

TAXONKIT_DATABASE = os.getenv("TAXONKIT_DATABASE")

HEADER = ["superkingdom", "kingdom", "phylum", "class", "order", "family", "genus", "species"]


COLNAMES = [
    "qseqid",
    "qlen",
    "sseqid",
    "slen",
    "stitle",
    "pident",
    "qcovhsp",
    "evalue",
    "bitscore",
    "taxid",
]

RANK_COLS = [
    "superkingdom",
    "kingdom",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "species",
]


def get_options() -> argparse.Namespace:
    """
    Parse command line arguments and return the options.

    Returns:
        argparse.Namespace: An object containing the parsed command line options.
    """
    parser = argparse.ArgumentParser(description="Create taxonkit dataframe + blastx diamond")
    parser.add_argument(
        "-in",
        "--input_table",
        metavar="<path>",
        help="Table with hits",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output_table",
        metavar="<path>",
        help="Full path for takonkit + hit table",
        default="taxonkit_dataframe.tsv",
    )
    parser.add_argument(
        "-tx",
        "--taxon",
        metavar="<text>",
        choices=["virus", "all"],
        help="taxon for analysis",
        required=True,
    )
    parser.add_argument("-th", "--threads", metavar="<integer>", help="threads", default=1, type=int)

    options = parser.parse_args()

    return options


def update_ranks(group: pd.DataFrame) -> pd.DataFrame:

    if len(group) == 1:
        return group.iloc[0]

    max_bitscore = group["bitscore"].max()

    max_bitscore_rows = group[group["bitscore"] == max_bitscore]

    if len(max_bitscore_rows) == 1:
        return max_bitscore_rows.iloc[0]

    max_bitscore_rows.at[max_bitscore_rows.index[0], "taxid"] = pytaxonkit.lca(
        max_bitscore_rows["taxid"], data_dir=TAXONKIT_DATABASE
    )

    return max_bitscore_rows.iloc[0]


def lineage(taxids, threads):
    result = pytaxonkit.lineage(
        taxids,
        threads=threads,
        formatstr="{k};{K};{p};{c};{o};{f};{g};{s}",
        data_dir=TAXONKIT_DATABASE,
    )

    lineage_expanded = result["Lineage"].str.split(";", expand=True)
    lineage_expanded.columns = HEADER[: lineage_expanded.shape[1]]
    result = pd.concat([result, lineage_expanded], axis=1)
    result.drop(
        columns=[
            "Lineage",
            "Code",
            "Name",
            "LineageTaxIDs",
            "Rank",
            "FullLineage",
            "FullLineageTaxIDs",
            "FullLineageRanks",
        ],
        inplace=True,
    )
    result["TaxID"] = result["TaxID"].astype(str)
    result = result.rename(columns={"TaxID": "taxid"})
    return result


def create_taxonkit_dataframe(input_table: str, output: str, taxon: str, threads: int) -> None:

    input_table["taxid"] = input_table["taxid"].str.split(";").str[0]
    pandarallel.initialize(progress_bar=True, nb_workers=threads)
    result_df = input_table.groupby("qseqid").parallel_apply(lambda group: update_ranks(group)).reset_index(drop=True)
    taxids = result_df["taxid"].dropna().unique()

    lineage_df = lineage(taxids, threads)
    result_df["taxid"] = result_df["taxid"].astype(str)
    final_df = result_df.merge(lineage_df, on="taxid", how="left")

    if taxon == "virus":
        final_df = final_df[(final_df["superkingdom"] == "Viruses") | (final_df["superkingdom"].isna())]
    else:
        final_df = final_df[final_df["superkingdom"] != "Viruses"]

    final_df.to_csv(output, sep="\t", index=False)


def main() -> None:
    options = get_options()

    df = pd.read_csv(
        options.input_table, sep="\t", header=None, names=COLNAMES, dtype={"taxid": str, "bitscore": float}
    )

    if df.empty:
        return None

    create_taxonkit_dataframe(df, options.taxonkit_database, options.output_table, options.taxon, options.threads)


if __name__ == "__main__":
    main()
