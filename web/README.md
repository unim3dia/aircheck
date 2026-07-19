# Aircheck web edition

This folder is a static website. It streams audio directly from Internet Archive
and loads a transcript only after a visitor opens a broadcast.

## Refresh the web data

```sh
cd "/Users/aylon/CODING PROJECTS/aircheck-06"
python3 web/build_data.py
```

## Test locally

```sh
cd "/Users/aylon/CODING PROJECTS/aircheck-06"
python3 -m http.server 8787 --directory web
```

Open `http://localhost:8787` in a browser.

The `web` folder can be deployed unchanged to any static web host.
