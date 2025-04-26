#!/usr/bin/env python3

import argparse
import warnings

import pandas as pd

warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")


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
        "-out",
        "--output_table",
        metavar="<path>",
        help="RNA virus output table path",
        default="rna_virus.tsv",
    )
    parser.add_argument(
        "-q",
        "--rna_virus_queries",
        metavar="<path>",
        help="RNA virus queries path",
        default="rna_virus_queries.tsv",
    )

    options = parser.parse_args()

    return options


def create_taxon_list(data_base, column):
    taxon = data_base.groupby(column)["Genome"].unique().apply(", ".join).reset_index()
    taxon = taxon[
        ~taxon["Genome"].str.contains(
            "dsDNA|ssDNA\\(+\\)|ssDNA|dsDNA-RT|ssDNA\\(-\\)|ssDNA\\(\\+/-\\)",
            regex=True,
        )
    ]
    return taxon[column].tolist()


def add_type_rna(row, rna_all_virus_species):
    if pd.notna(row["Genome"]):
        return row["Genome"]
    if row["Species"] in rna_all_virus_species:
        return "RNA"
    return "unknown"


def run_virus_filter(
    data_base: str,
    rna_virus: str,
    rna_virus_queries: str,
    input: str,
) -> None:

    data_base_df = pd.read_excel(data_base, sheet_name="VMR MSL40")
    diamond = pd.read_csv(input, sep="\t", header=0)

    virus_genus = create_taxon_list(data_base_df, "Genus")
    virus_phylum = create_taxon_list(data_base_df, "Phylum")
    virus_class = create_taxon_list(data_base_df, "Class")
    virus_order = create_taxon_list(data_base_df, "Order")
    virus_family = create_taxon_list(data_base_df, "Family")

    species = data_base_df[
        data_base_df["Genome"].isin(["dsRNA", "ssRNA", "ssRNA(-)", "ssRNA-RT", "ssRNA(+)", "ssRNA(+/-)"])
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

    concat_df = pd.concat([rna_all_virus, non_classified], axis=0).rename(
        columns={
            "phylum": "Phylum",
            "class": "Class",
            "order": "Order",
            "family": "Family",
            "genus": "Genus",
            "species": "Species",
        }
    )

    data_base_df_filtered = data_base_df.drop(
        columns=[
            "Realm",
            "Subrealm",
            "Kingdom",
            "Subkingdom",
            "Phylum",
            "Subphylum",
            "Class",
            "Subclass",
            "Order",
            "Suborder",
            "Family",
            "Subfamily",
            "Genus",
            "Subgenus",
        ]
    ).copy()
    merged_df = concat_df.merge(data_base_df_filtered, how="left", on="Species")
    rna_all_virus_species = rna_all_virus["species"].tolist()

    merged_df["Genome"] = merged_df.apply(lambda row: add_type_rna(row, rna_all_virus_species), axis=1)
    merged_df.to_csv("test.tsv", sep="\t", index=False)
    merged_df = merged_df[merged_df["Family"] != "Retroviridae"]

    merged_df.to_csv(rna_virus, sep="\t", index=False)

    merged_df.iloc[:, 0].to_csv(rna_virus_queries, sep="\t", index=False, header=None)


def main() -> None:
    options = get_options()
    run_virus_filter(
        options.data_base,
        options.output_table,
        options.rna_virus_queries,
        options.input,
    )


if __name__ == "__main__":
    main()
