# ms-marco-reranker-flake

A Nix flake that publishes [cross-encoder/ms-marco-MiniLM-L6-v2](https://huggingface.co/cross-encoder/ms-marco-MiniLM-L6-v2) — a [sentence-transformers](https://www.sbert.net/) cross-encoder re-ranker (BERT `BertForSequenceClassification`, `text-ranking`) — as a Nix store path. The files are fetched and hash-verified at build time, so a consumer loads the model out of its own store with no download at run time.

## Outputs

- `packages.<system>.model` — a directory containing `config.json`, `model.safetensors`, `tokenizer.json`, `tokenizer_config.json`, `special_tokens_map.json`, and `vocab.txt`: about 92 MB together, of which `model.safetensors` is just over 90 MB. `packages.<system>.default` is the same derivation.
- `packages.<system>.update-version` — maintenance output, not needed to consume the flake.

`<system>` covers `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. There are no overlays, devShells, or apps.

## Consuming

```nix
inputs.ms-marco-reranker-flake.url = "github:jgus-org/ms-marco-reranker-flake";
```

```nix
# wired into a package set
input-pkgs.ms-marco-reranker = ms-marco-reranker-flake.packages.${system}.default;
```

Hand the path to anything that loads a model from a local directory:

```python
from sentence_transformers import CrossEncoder

model = CrossEncoder("/nix/store/…-ms-marco-MiniLM-L6-v2")
scores = model.predict([("Which planet is the Red Planet?", "Mars is the fourth planet from the Sun.")])
```

## What you get

**No executable, no runtime.** The output is a model directory. This flake provides no Python interpreter, `torch`, or `sentence-transformers`, and no service that serves the model — the consumer supplies whatever reads the directory.

**Safetensors only.** Upstream also publishes `pytorch_model.bin` and Flax, ONNX, and OpenVINO variants. None of them are published here, so an ONNX or OpenVINO loader cannot be pointed at this path.

**Read-only.** Nothing can be written beside the weights. A loader that caches a converted or compiled artifact next to the model needs to point that cache somewhere else.

**Network at build time.** The downloads are build actions, so a builder without access to `huggingface.co` cannot realize this package; substituting a prebuilt store path hides that.

**No version to choose.** Upstream names no releases, so there is nothing to select: the artifact is pinned to one commit of the model repository, and the content a consumer gets changes only when that consumer re-pins this flake.

Following this flake's `nixpkgs` is safe — what the package contains is fixed by the per-file hashes and does not depend on the package set it is built with.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
