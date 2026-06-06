#!/usr/bin/env python

# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "requests>=2.31.0",
# ]
# ///

import requests
import time
import logging
from pathlib import Path
from typing import Optional
import argparse
import random

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class FoldSeekAPI:
    def __init__(self, base_url: str = "https://search.foldseek.com/api", request_delay: float = 1.0):
        self.base_url = base_url
        self.databases = [
            "afdb50",
            "afdb-swissprot",
            "afdb-proteome",
            "pdb100",
            "BFVD",
            "mgnify_esm30",
            "cath50",
            "gmgcl_id",
            "bfmd",
        ]
        self.request_delay = request_delay

    def submit_search(self, file_path: Path) -> Optional[str]:
        url = f"{self.base_url}/ticket"
        with open(file_path, "rb") as f:
            files = {"q": f}
            data = [("mode", "3diaa")]
            for db in self.databases:
                data.append(("database[]", db))
            
            try:
                response = requests.post(url, files=files, data=data)
                response.raise_for_status()
                result = response.json()
                return result.get("id")
            except requests.exceptions.HTTPError as e:
                if e.response.status_code == 429:
                    logger.warning(f"Rate limited on {file_path.name}, will retry later")
                    return None
                logger.error(f"Error submitting {file_path.name}: {e}")
                return None
            except requests.exceptions.RequestException as e:
                logger.error(f"Error submitting {file_path.name}: {e}")
                return None

    def get_status(self, ticket_id: str) -> Optional[str]:
        url = f"{self.base_url}/ticket/{ticket_id}"
        try:
            response = requests.get(url)
            response.raise_for_status()
            status_data = response.json()
            return status_data.get("status")
        except requests.exceptions.RequestException as e:
            logger.error(f"Error checking status for {ticket_id}: {e}")
            return None

    def download_results(self, ticket_id: str, output_file: Path) -> bool:
        url = f"{self.base_url}/result/download/{ticket_id}"
        try:
            response = requests.get(url)
            response.raise_for_status()
            with open(output_file, "wb") as f:
                f.write(response.content)
            logger.info(f"Downloaded results to {output_file}")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Error downloading results for {ticket_id}: {e}")
            return False

    def wait_for_completion(self, ticket_id: str, poll_interval: int = 10, timeout: int = 600) -> bool:
        start_time = time.time()
        while time.time() - start_time < timeout:
            status = self.get_status(ticket_id)
            if not status:
                return False
            
            if status == "COMPLETE":
                logger.info(f"Ticket {ticket_id} completed")
                return True
            elif status == "ERROR":
                logger.error(f"Ticket {ticket_id} failed")
                return False
            else:
                logger.info(f"Ticket {ticket_id} status: {status}")
                time.sleep(poll_interval)
        
        logger.error(f"Ticket {ticket_id} timed out after {timeout} seconds")
        return False

    def search_file(self, file_path: Path, output_dir: Path) -> bool:
        max_retries = 3
        for attempt in range(max_retries):
            ticket_id = self.submit_search(file_path)
            
            if ticket_id is None and attempt < max_retries - 1:
                delay = self.request_delay * (attempt + 1) * random.uniform(1, 2)
                logger.info(f"Rate limited, waiting {delay:.1f}s before retry...")
                time.sleep(delay)
                continue
            elif not ticket_id:
                return False
            
            logger.info(f"Ticket ID: {ticket_id}")
            
            if not self.wait_for_completion(ticket_id):
                return False
            
            rel_path = file_path.relative_to(Path("runs"))
            output_name = str(rel_path).replace("/", "_").replace(".cif", "").replace(".pdb", "")
            output_file = output_dir / f"{output_name}_foldseek.tsv"
            return self.download_results(ticket_id, output_file)
        
        logger.error(f"Failed after {max_retries} attempts for {file_path.name}")
        return False


def find_design_files(runs_dir: Path) -> list:
    files = []
    for ext in ["*.pdb", "*.cif"]:
        files.extend(runs_dir.rglob(ext))
    return sorted(files)


def main():
    parser = argparse.ArgumentParser(description="Run FoldSeek on BoltzGen designs")
    parser.add_argument("--runs-dir", type=str, default="runs", help="Directory containing design files")
    parser.add_argument("--output-dir", type=str, default="foldseek_results", help="Output directory for results")
    parser.add_argument("--max-files", type=int, default=None, help="Limit number of files to process")
    parser.add_argument("--skip-existing", action="store_true", help="Skip files that already have results")
    parser.add_argument("--delay", type=float, default=2.0, help="Delay between requests in seconds")
    args = parser.parse_args()

    runs_dir = Path(args.runs_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)

    design_files = find_design_files(runs_dir)
    
    if args.max_files:
        design_files = design_files[:args.max_files]
    
    if args.skip_existing:
        existing_results = {f.stem.replace("_foldseek", "") for f in output_dir.glob("*_foldseek.tsv")}
        design_files = [f for f in design_files if f.stem not in existing_results]
    
    logger.info(f"Found {len(design_files)} design files to process")
    
    api = FoldSeekAPI(request_delay=args.delay)
    
    success_count = 0
    failed_count = 0
    
    for i, file_path in enumerate(design_files, 1):
        logger.info(f"Processing {i}/{len(design_files)}: {file_path.name}")
        if api.search_file(file_path, output_dir):
            success_count += 1
        else:
            failed_count += 1
        time.sleep(args.delay)
    
    logger.info(f"Complete: {success_count} successful, {failed_count} failed")


if __name__ == "__main__":
    main()
