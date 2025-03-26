#!/usr/bin/env python3

import argparse
import logging
import signal
import time
import xml.etree.ElementTree as ET
from urllib.error import HTTPError

from Bio import Entrez

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

TIMEOUT_LIMIT = 600


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download host data")
    parser.add_argument("-s", "--sra_accession", metavar="<text>", help="SRA Accession", required=True)
    parser.add_argument("-e", "--email", metavar="<text>", help="email", default="anonymous@gmail.com")
    parser.add_argument("-t", "--timeout", metavar="<int>", help="timout limit", default=TIMEOUT_LIMIT)
    options = parser.parse_args()

    return options


class TimeoutError(Exception):
    pass


def handler(signum, frame):
    raise TimeoutError("Process timed out. Retrying...")


def get_xml(sample, email, timeout):
    tries = 0
    max_retries = 3
    Entrez.email = email

    while tries < max_retries:
        try:
            signal.signal(signal.SIGALRM, handler)
            signal.alarm(timeout)
            logging.info(f"Extracting {sample} info...")
            time.sleep(0.3)
            with Entrez.efetch(db="sra", rettype="xml", retmode="text", id=sample) as handle:
                root = ET.fromstring(handle.read())
                for experiment in root.findall(".//SAMPLE_NAME"):
                    query = experiment.find("SCIENTIFIC_NAME").text.strip()
                    return f"'{query}'" if query else "'Homo sapiens'"

        except TimeoutError as e:
            logging.warning(e)
            tries += 1

        except HTTPError as e:
            logging.warning(e)
            time.sleep(10)
            tries += 1

        finally:
            signal.alarm(0)

    logging.warning("Maximum retries reached. Using default value...")
    return "'Homo sapiens'"


def main():
    options = get_options()
    print(get_xml(options.sra_accession, options.email, options.timeout))


if __name__ == "__main__":
    main()
