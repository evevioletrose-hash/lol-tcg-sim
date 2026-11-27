"""Read-only comparison of external vault against the retired tracked archive."""
import argparse
import hashlib
import json
from pathlib import Path

def blob_hash(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+b"\0"+data).hexdigest()

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("vault",type=Path)
    args=p.parse_args()
    root=args.vault.resolve()
    if not root.is_dir():p.error("Vault not found")
    inventory=json.loads((Path(__file__).resolve().parents[1]/"evidence/legacy-archive-inventory.json").read_text(encoding="utf-8"))
    exact=0; normalized=0; issues=[]
    for row in inventory["files"]:
        path=(root/row["path"]).resolve()
        if not path.is_relative_to(root) or not path.is_file():
            issues.append("MISSING "+row["path"]);continue
        data=path.read_bytes()
        if len(data)==row["bytes"] and blob_hash(data)==row["git_blob_sha1"]:
            exact+=1;continue
        # Only allow CRLF normalization for non-payload text files; raw archive
        # evidence must match bytes exactly. No mutation of the external file.
        if not row["path"].startswith("recovered/payloads/") and path.suffix.lower() in (".py",".json",".jsonl",".txt"):
            fixed=data.replace(b"\r\n",b"\n")
            if len(fixed)==row["bytes"] and blob_hash(fixed)==row["git_blob_sha1"]:
                normalized+=1;continue
        issues.append("DIFFERENT "+row["path"])
    for issue in issues:print(issue)
    print("Old tracked archive:",len(inventory["files"]),"files")
    print("Exact:",exact,"CRLF-equivalent text:",normalized,"issues:",len(issues))
    print("LEGACY ARCHIVE AUDIT:", "PASS" if not issues else "FAIL")
    return int(bool(issues))
if __name__=="__main__":raise SystemExit(main())
