#!/usr/bin/env python
"""Enhanced FoldSeek API integration for structural similarity search."""

# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "biopython>=1.83",
#   "gemmi>=0.6.4",
#   "pandas>=2.0.0",
#   "numpy>=2.0.0",
#   "requests>=2.31.0",
#   "rich>=13.0.0",
# ]
# ///

import argparse
import re
import subprocess
from pathlib import Path
from typing import Optional, List, Dict
import logging
import requests
import pandas as pd

FOLDSEEK_DATABASES = {
    "cath50": "CATH structural classification",
    "afdb50": "AlphaFold DB (50% clustered)",
    "pdb100": "PDB structures",
    "afdb-swissprot": "SwissProt AlphaFold",
    "BFVD": "Beta-fold vantage database",
    "mgnify_esm30": "MGnify ESM-30",
    "gmgcl_id": "GMGCL identifier database",
    "bfmd": "Beta-fold metadata database"
}

RCSB_DOWNLOAD_BASE = "https://files.rcsb.org/download/"


def _validate_pdb_id(pdb_id: str) -> bool:
    return bool(re.match(r"^[0-9A-Za-z]{4}$", pdb_id))


def _fetch_from_rcsb(pdb_id: str, output_dir: Path, format: str = "pdb") -> Optional[Path]:
    if not _validate_pdb_id(pdb_id):
        logger.error(f"Invalid PDB ID: {pdb_id}")
        return None
    pdb_id = pdb_id.lower()
    if format == "pdb":
        filename = f"pdb{pdb_id}.ent"
        url = f"{RCSB_DOWNLOAD_BASE}{filename}"
    elif format == "cif":
        filename = f"{pdb_id}.cif"
        url = f"{RCSB_DOWNLOAD_BASE}{filename}"
    else:
        logger.error(f"Unsupported format: {format}")
        return None
    output_path = output_dir / filename
    output_dir.mkdir(parents=True, exist_ok=True)
    try:
        logger.info(f"Fetching from {url}")
        result = subprocess.run(
            ["curl", "-sSfL", "-o", str(output_path), url],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode != 0:
            logger.error(f"Failed to fetch PDB {pdb_id}: {result.stderr or result.stdout}")
            return None
        logger.info(f"Saved to {output_path}")
        return output_path
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        logger.error(f"Failed to fetch PDB {pdb_id}: {e}")
        return None

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


class FoldSeekSearcher:
    """Enhanced FoldSeek API interface."""
    
    FOLDSEEK_API_URL = "https://search.foldseek.steineggerlab.de/api/search"
    
    def __init__(self, structure_file: Optional[Path] = None, pdb_id: Optional[str] = None):
        """Initialize with structure file or PDB ID."""
        self.structure_file = structure_file
        self.pdb_id = pdb_id
        
        if not structure_file and not pdb_id:
            raise ValueError("Must provide either structure_file or pdb_id")
        
        if pdb_id and not _validate_pdb_id(pdb_id):
            raise ValueError(f"Invalid PDB ID: {pdb_id}")
        
        self.temp_dir = None
    
    def _ensure_structure_file(self) -> Path:
        """Ensure we have a local structure file."""
        if self.structure_file:
            return self.structure_file
        
        if not self.temp_dir:
            from tempfile import mkdtemp
            self.temp_dir = Path(mkdtemp())
        
        fetched = _fetch_from_rcsb(self.pdb_id or "", self.temp_dir, "pdb")
        if not fetched:
            raise RuntimeError(f"Failed to fetch PDB {self.pdb_id}")
        
        return fetched
    
    def search_by_file(
        self,
        structure_file: Path,
        databases: Optional[List[str]] = None,
        top_hits: int = 20
    ) -> Optional[pd.DataFrame]:
        """Search by structure file."""
        if not structure_file.exists():
            logger.error(f"Structure file not found: {structure_file}")
            return None
        
        if not databases:
            databases = ["cath50"]
        
        databases_str = ",".join(databases)
        
        logger.info(f"Searching {len(databases)} database(s)...")
        logger.info(f"Databases: {databases_str}")
        
        return self._submit_search(structure_file, databases_str, top_hits)
    
    def search_by_pdb_id(
        self,
        pdb_id: str,
        databases: Optional[List[str]] = None,
        top_hits: int = 20
    ) -> Optional[pd.DataFrame]:
        """Search by PDB ID (auto-fetches structure)."""
        if not _validate_pdb_id(pdb_id):
            logger.error(f"Invalid PDB ID: {pdb_id}")
            return None
        
        if not databases:
            databases = ["cath50"]
        
        from tempfile import mkdtemp
        temp_dir = Path(mkdtemp())
        
        structure_file = _fetch_from_rcsb(pdb_id, temp_dir, "pdb")
        if not structure_file:
            logger.error(f"Failed to fetch PDB {pdb_id}")
            return None
        
        databases_str = ",".join(databases)
        logger.info(f"Searching for PDB {pdb_id} against {len(databases)} database(s)")
        
        result = self._submit_search(structure_file, databases_str, top_hits)
        
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)
        
        return result
    
    def search_cath_only(self, structure_file: Path, top_hits: int = 20) -> Optional[pd.DataFrame]:
        """Search against CATH50 database only."""
        return self.search_by_file(structure_file, ["cath50"], top_hits)
    
    def search_afdb(self, structure_file: Path, top_hits: int = 20) -> Optional[pd.DataFrame]:
        """Search against AlphaFold DB."""
        return self.search_by_file(structure_file, ["afdb50"], top_hits)
    
    def search_pdb(self, structure_file: Path, top_hits: int = 20) -> Optional[pd.DataFrame]:
        """Search against PDB100 database."""
        return self.search_by_file(structure_file, ["pdb100"], top_hits)
    
    def _submit_search(
        self,
        structure_file: Path,
        databases: str,
        top_hits: int
    ) -> Optional[pd.DataFrame]:
        """Submit search request to FoldSeek API."""
        import time
        
        try:
            with open(structure_file, "rb") as f:
                files = {"file": f}
                data = {
                    "databases": databases,
                    "max-seqs": str(top_hits)
                }
                
                logger.info("Submitting search to FoldSeek API...")
                response = requests.post(
                    self.FOLDSEEK_API_URL,
                    files=files,
                    data=data,
                    timeout=60
                )
                response.raise_for_status()
                
                result = response.json()
                
                if "ticket" not in result:
                    logger.error("No ticket returned from FoldSeek API")
                    return None
                
                ticket = result["ticket"]
                logger.info(f"Got ticket: {ticket}")
                
                results = self._poll_for_results(ticket)
                return results
        
        except requests.RequestException as e:
            logger.error(f"FoldSeek API request failed: {e}")
            return None
        except Exception as e:
            logger.error(f"FoldSeek search failed: {e}")
            return None
    
    def _poll_for_results(self, ticket: str, max_attempts: int = 30) -> Optional[pd.DataFrame]:
        """Poll for search results."""
        import time
        
        poll_url = f"{self.FOLDSEEK_API_URL}?ticket={ticket}"
        
        for attempt in range(max_attempts):
            try:
                time.sleep(10)
                
                logger.info(f"Polling for results (attempt {attempt + 1}/{max_attempts})...")
                
                response = requests.get(poll_url, timeout=30)
                response.raise_for_status()
                
                result = response.json()
                
                if result.get("status") == "RUNNING":
                    logger.info("Search still running...")
                    continue
                
                if result.get("status") == "COMPLETE":
                    logger.info("Search complete!")
                    return self._parse_results(result)
                
                if result.get("status") == "FAILED":
                    logger.error("Search failed")
                    return None
            
            except requests.RequestException as e:
                logger.warning(f"Poll attempt failed: {e}")
                if attempt < max_attempts - 1:
                    continue
                else:
                    logger.error("Max polling attempts reached")
                    return None
        
        logger.error("Timeout waiting for results")
        return None
    
    def _parse_results(self, result: Dict) -> pd.DataFrame:
        """Parse FoldSeek results into DataFrame."""
        if "results" not in result:
            logger.warning("No results in response")
            return pd.DataFrame()
        
        results_data = []
        for item in result["results"]:
            results_data.append({
                "target": item.get("target", ""),
                "alnlen": item.get("alnlen", 0),
                "tmscore": item.get("tmscore", 0.0),
                "seq_id": item.get("seq_id", ""),
                "evalue": item.get("evalue", 1.0),
                "prob": item.get("prob", 0.0),
                "u": item.get("u", ""),
                "t": item.get("t", ""),
                "alntmscore": item.get("alntmscore", 0.0),
                "lddt": item.get("lddt", 0.0),
                "rmsd": item.get("rmsd", 0.0),
                "probconf": item.get("probconf", 0.0),
                "ustart": item.get("ustart", 0),
                "uend": item.get("uend", 0),
                "tstart": item.get("tstart", 0),
                "tend": item.get("tend", 0),
                "u_alnlen": item.get("u_alnlen", 0),
                "t_alnlen": item.get("t_alnlen", 0),
                "cov": item.get("cov", 0.0),
                "db": item.get("db", "")
            })
        
        df = pd.DataFrame(results_data)
        
        if not df.empty:
            df = df.sort_values("tmscore", ascending=False)
            logger.info(f"Parsed {len(df)} results")
            logger.info(f"Top hit: {df.iloc[0]['target'] if len(df) > 0 else 'None'} (TM-score: {df.iloc[0]['tmscore']:.2f if len(df) > 0 else 'N/A'})")
        
        return df


def main():
    parser = argparse.ArgumentParser(description="Search for structurally similar proteins using FoldSeek")
    parser.add_argument("--structure-file", type=Path, help="Input structure file (PDB/CIF)")
    parser.add_argument("--pdb-id", help="PDB ID to fetch and search (alternative to structure-file)")
    parser.add_argument("--databases", help="Databases to search (comma-separated, e.g., cath50,afdb50)")
    parser.add_argument("--cath-only", action="store_true", help="Search CATH50 database only")
    parser.add_argument("--afdb-only", action="store_true", help="Search AlphaFold DB only")
    parser.add_argument("--pdb-only", action="store_true", help="Search PDB100 only")
    parser.add_argument("--top-hits", type=int, default=20, help="Number of top hits to return (default: 20)")
    parser.add_argument("--output-dir", type=Path, default=Path("."), help="Output directory (default: current)")
    
    args = parser.parse_args()
    
    if not args.structure_file and not args.pdb_id:
        logger.error("Must provide either --structure-file or --pdb-id")
        return 1
    
    try:
        if args.pdb_id:
            searcher = FoldSeekSearcher(pdb_id=args.pdb_id)
            structure = searcher._ensure_structure_file()
        else:
            structure = args.structure_file
            searcher = FoldSeekSearcher(structure_file=structure)
        
        databases = None
        if args.databases:
            databases = [db.strip() for db in args.databases.split(",")]
        elif args.cath_only:
            databases = ["cath50"]
        elif args.afdb_only:
            databases = ["afdb50"]
        elif args.pdb_only:
            databases = ["pdb100"]
        
        results = searcher.search_by_file(structure, databases, args.top_hits)
        
        if results is not None and not results.empty:
            output_file = args.output_dir / f"{structure.stem}_foldseek_results.tsv"
            results.to_csv(output_file, sep="\t", index=False)
            logger.info(f"Results saved to {output_file}")
            
            print("\nTop 10 hits:")
            print(results.head(10).to_string(index=False))
            
            return 0
        else:
            logger.error("No results returned")
            return 1
    
    except Exception as e:
        logger.error(f"Search failed: {e}")
        return 1


if __name__ == "__main__":
    exit(main())
