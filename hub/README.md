# Delivery hub snapshot

`page.tsx` here is the byte-exact snapshot of the delivery hub page
(`/home/z/my-project/src/app/page.tsx`) at the WB-20 era (142 proof cards).
The hub lives OUTSIDE this repo (the Next.js project has no remote), so after
any sandbox wipe: restore the page from this snapshot, and rebuild the JPEGs
with `tools/proofs_to_hub.sh` + the wb18 stills (see backups/RESTORE.md).
Snapshot policy: refresh this file in the same commit that changes the hub.
