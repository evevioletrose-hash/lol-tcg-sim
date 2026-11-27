"""Read-only verification of the private Valkyrie evidence copy."""
import argparse,base64,hashlib,json
from pathlib import Path
def sha(p,algorithm="sha256"):
    h=hashlib.new(algorithm)
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""):h.update(b)
    return h.digest()
def digest(p):return base64.b32encode(sha(p,"sha1")).decode()
def read(p):return json.loads(p.read_text(encoding="utf-8"))
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("vault",type=Path)
    p.add_argument("--compare-source",type=Path)
    a=p.parse_args();v=a.vault.resolve()
    issues=[]
    if not v.is_dir():p.error("Vault folder not found")
    if a.compare_source:
        src=a.compare_source.resolve()
        if not src.is_dir():p.error("Source folder not found")
        count=0
        for f in src.rglob("*"):
            if f.is_file():
                q=v/f.relative_to(src)
                if not q.is_file() or sha(f)!=sha(q):issues.append("Copy mismatch: "+str(f.relative_to(src)))
                else:count+=1
        print("Copied source files verified:",count)
    captures=v/"temporal/captures.json"; manifest=v/"recovered/manifest.json"
    if not captures.is_file() or not manifest.is_file():p.error("Expected vault/recovered and vault/temporal; copy archaeology contents to vault root")
    rows=read(captures); empty=base64.b32encode(hashlib.sha1(b"").digest()).decode()
    wanted={r["digest"] for r in rows if r["statuscode"]=="200" and r["digest"] not in ("-",empty)}
    found=set()
    for r in read(manifest):
        if r.get("status")!="recovered":continue
        q=(v/"recovered"/r["path"]).resolve()
        if q.is_relative_to(v/"recovered") and q.is_file() and digest(q)==r["digest"] and sha(q).hex()==r["sha256"]:found.add(r["digest"])
    for d in wanted-found:
        q=v/"temporal/objects"/d
        if q.is_file() and digest(q)==d:found.add(d)
    missing=wanted-found
    print("Capture rows:",len(rows),"verified nonempty:",len(wanted&found),"/",len(wanted))
    if missing:issues.extend("Missing digest: "+d for d in sorted(missing))
    if len(rows)<438 or len(wanted)<317:issues.append("Archive below known baseline")
    dossiers=[x.parent for x in v.rglob("screenshots.json") if (x.parent/"sources.json").is_file() and (x.parent/"12 - Screen atlas/screen-index.json").is_file()]
    if len(dossiers)!=1:p.error("Expected one complete dossier; found "+str(len(dossiers)))
    d=dossiers[0];screens=read(d/"screenshots.json");n=0
    for r in screens:
        q=(d/r["file"]).resolve()
        if q.is_relative_to(d) and q.is_file():n+=1
        else:issues.append("Missing screenshot: "+r["file"])
    print("Screenshots present:",n,"/",len(screens))
    atlas=read(d/"12 - Screen atlas/screen-index.json");n_atlas=0
    for r in atlas:
        q=(d/r["original_screenshot"]).resolve()
        if q.is_relative_to(d) and q.is_file() and sha(q).hex()==r["screenshot_sha256"]:n_atlas+=1
        else:issues.append("Atlas anchor mismatch: "+r["original_screenshot"])
    print("Atlas anchors verified:",n_atlas,"/",len(atlas))
    videos=read(d/"sources.json")
    # Only search actual video folders, not the hundreds of recovered NFT clips.
    roots=[x for x in v.rglob("youtube-videos") if x.is_dir()]
    hashes={sha(q).hex() for root in roots for q in root.rglob("*") if q.is_file() and q.suffix.lower() in (".mp4",".webm",".mov",".mkv")}
    n_vid=sum(r["sha256"] in hashes for r in videos)
    for r in videos:
        if r["sha256"] not in hashes:issues.append("Missing source video: "+r["id"])
    print("Source videos verified:",n_vid,"/",len(videos))
    if n<888 or n_atlas<41 or n_vid<4:issues.append("Dossier below known baseline")
    for e in issues:print("ISSUE:",e)
    print("VAULT AUDIT:", "PASS" if not issues else "FAIL")
    return int(bool(issues))
if __name__=="__main__":raise SystemExit(main())
