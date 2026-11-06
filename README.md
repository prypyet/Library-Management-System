# Library Book and Circulation Management Dashboard

Library Book and Circulation Management Dashboard — Linux/Bash/web practical starter project.

## Run in GitHub Codespaces
1. Open this folder in an Ubuntu GitHub Codespace.
2. Install dependencies:
   `sudo apt update && sudo apt install -y busybox build-essential python3`
3. From this project folder run:
   `bash scripts/build.sh`
   `bash scripts/run.sh`
4. In the Codespaces **Ports** tab, open port **8080** in the browser.
5. Test the endpoint in the terminal:
   `curl http://127.0.0.1:8080/cgi-bin/data.sh`

## Folder contents
- `data/` — sample CSV or log records
- `public/` — browser dashboard files
- `public/cgi-bin/data.sh` — Bash CGI endpoint; Python standard library is used for robust CSV/JSON parsing
- `scripts/` — build and run scripts
- `src/` — optional C source

## Notes
- Sample data is fictional and intended for classroom practice.
- CGI requires a CGI-enabled BusyBox build. If `/cgi-bin/data.sh` does not execute, verify BusyBox CGI support/server configuration.
- A static server such as `python3 -m http.server` does not execute Bash CGI scripts.

## Data path note
The CGI endpoint resolves the project root relative to `public/cgi-bin`, then reads the sample files from this project's `data/` folder. Test it with `curl http://127.0.0.1:8080/cgi-bin/data.sh`.
# generic
