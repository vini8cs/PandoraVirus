#!/usr/bin/env python3

import argparse

import pandas as pd


def get_options() -> argparse.Namespace:
    """
    Parse command line arguments and return the options.

    Returns:
        argparse.Namespace: An object containing the parsed command line options.
    """
    parser = argparse.ArgumentParser(description="Create taxonkit dataframe + blastx diamond")
    parser.add_argument(
        "-d",
        "--data_base",
        metavar="<path>",
        help="ICTV virus database",
        required=True,
    )
    parser.add_argument(
        "-in",
        "--input",
        metavar="<path>",
        help="taxonomy input table",
        required=True,
    )
    parser.add_argument(
        "-out", "--output_table", metavar="<path>", help="RNA virus output table path", default="rna_virus.tsv"
    )
    parser.add_argument(
        "-q", "--rna_virus_queries", metavar="<path>", help="RNA virus queries path", default="rna_virus_queries.tsv"
    )

    options = parser.parse_args()

    return options


def create_taxon_list(data_base, column):
    taxon = data_base.groupby(column)["Genome composition"].unique().apply(", ".join).reset_index()
    taxon = taxon[
        ~taxon["Genome composition"].str.contains(
            "dsDNA|ssDNA\\(+\\)|ssDNA|dsDNA-RT|ssDNA\\(-\\)|ssDNA\\(\\+/-\\)",
            regex=True,
        )
    ]
    return taxon[column].tolist()


def run_virus_filter(
    data_base: str,
    rna_virus: str,
    rna_virus_queries: str,
    output_taxonkit: str,
) -> None:

    data_base_df = pd.read_excel(data_base)
    diamond = pd.read_csv(output_taxonkit, sep="\t", header=0)

    virus_genus = create_taxon_list(data_base_df, "Genus")
    virus_phylum = create_taxon_list(data_base_df, "Phylum")
    virus_class = create_taxon_list(data_base_df, "Class")
    virus_order = create_taxon_list(data_base_df, "Order")
    virus_family = create_taxon_list(data_base_df, "Family")

    species = data_base_df[
        data_base_df["Genome composition"].isin(["dsRNA", "ssRNA", "ssRNA(-)", "ssRNA-RT", "ssRNA(+)", "ssRNA(+/-)"])
    ]
    virus_species = species["Species"].tolist()

    diamond = diamond.fillna("")

    rna_all_virus = diamond[
        (diamond["phylum"].isin(virus_phylum))
        | (diamond["class"].isin(virus_class))
        | (diamond["order"].isin(virus_order))
        | (diamond["family"].isin(virus_family))
        | (diamond["genus"].isin(virus_genus))
        | (diamond["species"].isin(virus_species))
    ].copy()

    non_classified = diamond[
        ~(diamond["species"].isin(data_base_df["Species"].to_list()))
        & ~(diamond["phylum"].isin(data_base_df["Phylum"].to_list()))
        & ~(diamond["class"].isin(data_base_df["Class"].to_list()))
        & ~(diamond["order"].isin(data_base_df["Order"].to_list()))
        & ~(diamond["family"].isin(data_base_df["Family"].to_list()))
        & ~(diamond["genus"].isin(data_base_df["Genus"].to_list()))
    ].copy()

    if not rna_all_virus.empty:
        rna_all_virus["virus_type"] = "RNA"
    if not non_classified.empty:
        non_classified["virus_type"] = "unknown"

    rna_all_virus = rna_all_virus[rna_all_virus["family"] != "Retroviridae"]

    diamond = pd.concat([rna_all_virus, non_classified], axis=0)

    diamond.to_csv(rna_virus, sep="\t", index=False)

    diamond.iloc[:, 0].to_csv(rna_virus_queries, sep="\t", index=False, header=None)


def main() -> None:
    options = get_options()
    run_virus_filter(
        options.data_base, options.rna_virus_info, options.rna_virus_queries, options.takonkit_diamond_table
    )


if __name__ == "__main__":
    main()
