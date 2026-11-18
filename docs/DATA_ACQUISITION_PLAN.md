# Mars Pathfinder — Scientific Data Acquisition Plan

**Standard**: NASA Planetary Data System (PDS) / WUSTL PDS Geosciences Node  
**Status**: Authoritative Data Acquisition Specification — Fully Validated  

---

## 1. Data Acquisition Architecture

The Data Acquisition Engine (`processing/acquisition/downloader.py`) automates reliable, verifiable retrieval of scientific datasets from NASA PDS nodes and USGS repositories.

### Robust HTTP Range Handling (RFC 7233 Standard Compliance)
Planetary datasets frequently exceed tens or hundreds of megabytes. The acquisition engine implements a multi-phase protocol:

1. **Pre-flight Inspection (HTTP HEAD)**:
   * Queries upstream server headers without transferring payload.
   * Extracts `Content-Length` (total file size) and verifies available local disk storage.
   * Inspects `Accept-Ranges: bytes` to determine server resumption support.
   * Compares existing local file size with expected total size. If sizes match, tests checksum and returns `already_downloaded`.

2. **Resumable Chunk Transfer (HTTP Range GET)**:
   * If a partial file exists of size $S > 0$ and the server supports ranges, requests `Range: bytes={S}-`.
   * **Status 206 (Partial Content)**: Server honors byte range. File is opened in append binary mode (`"ab"`) and streamed in 64 KB chunks.
   * **Status 200 (OK)**: Server ignored range header or does not support resumption. Partial file is truncated to 0 bytes and overwritten from the beginning (`"wb"`).
   * **Status 416 (Range Not Satisfiable)**: Indicates existing file is already equal to or larger than the remote resource. Complete status is verified.

3. **Authoritative Checksum Integrity Verification**:
   * **Strict Verification Policy**: Checksums (SHA-256 / MD5) are evaluated against authoritative hash values published in NASA PDS volume descriptors (`VOLDESC.CAT`), label files, or MD5 checksum tables.
   * **No Synthetic Checksums**: When authoritative hashes are not published upstream, the engine calculates the file hash for provenance logging but marks `checksum_verified: false` to avoid false assurance.
   * **Failure Handling**: On checksum mismatch, the corrupted file is quarantined and an `IntegrityError` is thrown.

---

## 2. PDS Detached Label & Binary Raster Pair Acquisition

For every NASA PDS3 product, two files must be downloaded and verified together:
1. **Detached ASCII Label (`.lbl`)**: Contains record structures, pointers (`^IMAGE`), projection offsets, and radiometric scale factors.
2. **Binary Experiment Gridded Data Record (`.img`)**: The uncompressed raw binary matrix (16-bit big-endian integer `>i2`).

### Acquisition Priority Staging

| Priority | Product Identifier | Resolution | Upstream PDS URL | Size | Status |
|:---:|:---:|:---:|:---|:---:|:---:|
| **P1** | `MEGT90N000CB` | 4 ppd (~14.8 km) | `https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg004/` | 2.07 MB | **DOWNLOADED & VALIDATED** |
| **P2** | `MEGT90N000EB` | 16 ppd (~3.7 km) | `https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg016/` | 33.18 MB | Staged in Catalog |
| **P3** | `MEGT90N000FB` | 32 ppd (~1.85 km) | `https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg032/` | 132.71 MB | Staged in Catalog |
| **P4** | `MEGT90N000GB` (NW) | 64 ppd (~926 m) | `https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg064/` | 132.71 MB | Tiled Product |
| **P5** | `MEGT44N000HB` (Jezero) | 128 ppd (~463 m) | `https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg128/` | 129.76 MB | Tiled Regional |

---

## 3. Provenance & Metadata Tracking

Every acquired product is logged to `data/metadata/provenance.json` with UTC acquisition timestamp, product ID, upstream URL, byte size, calculated SHA-256 and MD5 hashes, and validation state.
